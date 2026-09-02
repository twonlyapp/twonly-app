import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:twonly/src/utils/log.dart';

/// Keeps the [PlayerController] of a chat audio message alive across widget
/// rebuilds.
///
/// The message list recreates the state of all of its items whenever it scrolls
/// to a new position (sending a message does that), so a controller owned by
/// the widget itself would be disposed and re-prepared in the middle of the
/// playback. Controllers are cached by file path here and are only released
/// once no widget uses them any more.
class AudioPlaybackService {
  AudioPlaybackService._();

  static final AudioPlaybackService instance = AudioPlaybackService._();

  final Map<String, AudioPlayback> _playbacks = {};

  /// Waveforms of already released players so a re-created widget can draw the
  /// waveform right away instead of waiting for the extraction again.
  final Map<String, List<double>> _waveformCache = {};

  /// Returns the playback for [path], preparing the player on first use.
  ///
  /// Every [attach] must be paired with a [detach].
  AudioPlayback attach(String path, {required int noOfSamples}) {
    final playback = _playbacks.putIfAbsent(
      path,
      () => AudioPlayback._(path, _waveformCache[path] ?? const []),
    );
    playback._refCount++;
    unawaited(playback._prepare(noOfSamples));
    return playback;
  }

  /// Releases the playback again once nothing uses it any more.
  void detach(AudioPlayback playback) {
    playback._refCount--;
    if (playback._refCount > 0) return;
    // A rebuilding message list detaches and attaches within the same frame,
    // so only release the player when it was not picked up again.
    Timer(const Duration(milliseconds: 500), () {
      if (playback._refCount > 0) return;
      if (_playbacks[playback.path] != playback) return;
      _playbacks.remove(playback.path);
      if (playback.waveformData.isNotEmpty) {
        _waveformCache[playback.path] = playback.waveformData;
      }
      playback.controller.dispose();
    });
  }

  /// Starts [playback] and pauses any other audio message.
  Future<void> play(AudioPlayback playback) async {
    for (final other in _playbacks.values) {
      if (other == playback) continue;
      if (other.controller.playerState == PlayerState.playing) {
        await other.controller.pausePlayer();
      }
    }
    await playback.controller.startPlayer();
  }
}

class AudioPlayback {
  AudioPlayback._(this.path, List<double> cachedWaveform)
    : waveformData = List<double>.of(cachedWaveform);

  final String path;
  final PlayerController controller = PlayerController();

  /// Extracted waveform, empty until the extraction finished.
  List<double> waveformData;

  /// Playback speed, kept here so it survives a rebuild of the widget.
  double rate = 1;

  int _refCount = 0;
  Future<void>? _preparing;

  bool get isPlaying => controller.playerState == PlayerState.playing;

  /// Resolves once the player is prepared and the waveform is extracted.
  Future<void> get ready => _preparing ?? Future<void>.value();

  Future<void> setRate(double newRate) async {
    rate = newRate;
    await controller.setRate(newRate);
  }

  Future<void> _prepare(int noOfSamples) {
    return _preparing ??= () async {
      try {
        await controller.preparePlayer(
          path: path,
          // The waveform is extracted below so the extraction can be awaited.
          shouldExtractWaveform: false,
        );
        await controller.setFinishMode(finishMode: FinishMode.pause);
        if (waveformData.isEmpty) {
          waveformData = await controller.waveformExtraction
              .extractWaveformData(path: path, noOfSamples: noOfSamples);
          AudioPlaybackService.instance._waveformCache[path] = waveformData;
        }
      } catch (e) {
        Log.error('Could not prepare the audio player for $path: $e');
      }
    }();
  }
}
