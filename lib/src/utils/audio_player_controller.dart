import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/services.dart';
import 'package:twonly/src/utils/log.dart';

/// Allows player disposal to finish when Android has already released the
/// waveform decoder at end of stream.
class AudioPlayerController extends PlayerController {
  WaveformExtractionController? _extraction;

  @override
  WaveformExtractionController get waveformExtraction =>
      _extraction ??= _PlaybackWaveformExtraction(super.waveformExtraction);
}

class _PlaybackWaveformExtraction extends WaveformExtractionController {
  _PlaybackWaveformExtraction(this._delegate);

  final WaveformExtractionController _delegate;

  @override
  List<double> get waveformData => _delegate.waveformData;

  @override
  Stream<List<double>> get onCurrentExtractedWaveformData =>
      _delegate.onCurrentExtractedWaveformData;

  @override
  Stream<double> get onExtractionProgress => _delegate.onExtractionProgress;

  @override
  Future<List<double>> extractWaveformData({
    required String path,
    int? noOfSamples,
    int? noOfSamplesPerSecond,
  }) => _delegate.extractWaveformData(
    path: path,
    noOfSamples: noOfSamples,
    noOfSamplesPerSecond: noOfSamplesPerSecond,
  );

  @override
  Future<void> stopWaveformExtraction() async {
    try {
      await _delegate.stopWaveformExtraction();
    } on PlatformException catch (error) {
      if (error.code != 'error' ||
          error.message != 'codec is released already') {
        rethrow;
      }
      // Keep the workaround here so PlayerController.dispose can unregister
      // the player, close its streams and dispose its ChangeNotifier too.
      Log.warn('Waveform decoder was already released during audio cleanup');
    }
  }
}
