import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/audio_playback.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/native.notifications.dart';
import 'package:twonly/src/visual/elements/better_text.element.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/friendly_message_time.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_send_state_icon.dart';

class ChatAudioEntry extends StatefulWidget {
  const ChatAudioEntry({
    required this.message,
    required this.mediaService,
    required this.borderRadius,
    required this.info,
    super.key,
  });

  final Message message;
  final MediaFileService mediaService;
  final BorderRadius borderRadius;
  final BubbleInfo info;

  @override
  State<ChatAudioEntry> createState() => _ChatAudioEntryState();
}

class _ChatAudioEntryState extends State<ChatAudioEntry> {
  bool? _hasAudioFile;
  bool _hasTempFile = false;

  Message get message => widget.message;
  MediaFileService get mediaService => widget.mediaService;
  BorderRadius get borderRadius => widget.borderRadius;
  BubbleInfo get info => widget.info;

  @override
  void initState() {
    super.initState();
    _checkAudioFiles();
  }

  @override
  void didUpdateWidget(ChatAudioEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mediaService.mediaFile != oldWidget.mediaService.mediaFile) {
      _checkAudioFiles();
    }
  }

  Future<void> _checkAudioFiles() async {
    // Async checks keep audio discovery off the UI thread.
    // ignore: avoid_slow_async_io
    final hasTempFile = await mediaService.tempPath.exists();
    // ignore: avoid_slow_async_io
    final hasOriginalFile = await mediaService.originalPath.exists();
    final hasAudioFile = hasTempFile || hasOriginalFile;
    if (!mounted) return;
    setState(() {
      _hasTempFile = hasTempFile;
      _hasAudioFile = hasAudioFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasAudioFile != true) {
      return Container(); // media file was purged
    }

    final showTime = info.displayTime || message.modifiedAt != null;
    final messageTime = showTime ? FriendlyMessageTime(message: message) : null;
    final isDownloaded =
        mediaService.mediaFile.downloadState == DownloadState.ready ||
        mediaService.mediaFile.downloadState == null;
    // The player places the time below the waveform itself.
    final showsPlayer = info.text == '' && isDownloaded && _hasTempFile;

    return IntrinsicWidth(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
          // The player brings its own width, only the reactions below the
          // bubble may need more room.
          minWidth: info.minWidth,
        ),
        // Voice messages need a bit more room than the tightly padded media
        // bubbles.
        padding: info.padding.copyWith(top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: info.color,
          borderRadius: borderRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (info.text != '')
              Expanded(
                child: BetterText(
                  text: info.text,
                  textColor: info.textColor,
                ),
              )
            else
              Expanded(
                child: isDownloaded
                    ? (_hasTempFile
                          ? InChatAudioPlayer(
                              path: mediaService.tempPath.path,
                              message: message,
                              trailing: messageTime,
                            )
                          : Container())
                    : MessageSendStateIcon(
                        [message],
                        [mediaService.mediaFile],
                      ),
              ),
            if (!showsPlayer && messageTime != null) messageTime,
          ],
        ),
      ),
    );
  }
}

class InChatAudioPlayer extends StatefulWidget {
  const InChatAudioPlayer({
    required this.path,
    required this.message,
    this.trailing,
    super.key,
  });

  final String path;
  final Message message;

  /// Shown below the waveform, next to the remaining playback time.
  final Widget? trailing;

  @override
  State<InChatAudioPlayer> createState() => _InChatAudioPlayerState();
}

class _InChatAudioPlayerState extends State<InChatAudioPlayer> {
  static const double _maxWaveWidth = 170;
  static const double _waveHeight = 36;
  static const double _cursorWidth = 2.5;
  static const double _cursorHeight = 20;
  static const double _playSlotWidth = 34;
  static const _waveStyle = PlayerWaveStyle(
    spacing: 4,
    waveThickness: 2.5,
    scaleFactor: 80,
    showSeekLine: false,
  );

  AudioPlayback? _playback;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Width available for the waveform next to the play button and the time.
  double _waveWidth = _maxWaveWidth;

  int _position = 0;
  int _duration = 0;
  bool _isPlaying = false;

  /// The cursor is only shown once the message was started.
  bool get _showCursor => _isPlaying || _position > 0;

  double get _progress =>
      _duration <= 0 ? 0 : (_position / _duration).clamp(0.0, 1.0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Leaves room for the play button and the bubble padding.
    _waveWidth = (MediaQuery.sizeOf(context).width * 0.8 - 80).clamp(
      80.0,
      _maxWaveWidth,
    );
    if (_playback != null) return;

    // The player outlives this widget: the message list recreates its items
    // when it scrolls (e.g. after sending a message) and the playback must not
    // be interrupted by that.
    final playback = AudioPlaybackService.instance.attach(
      widget.path,
      noOfSamples: _waveStyle.getSamplesForWidth(_waveWidth) - 1,
    );
    _playback = playback;
    _isPlaying = playback.isPlaying;
    _duration = playback.controller.maxDuration;

    _subscriptions.add(
      playback.controller.onPlayerStateChanged.listen((state) {
        if (!mounted) return;
        setState(() => _isPlaying = state == PlayerState.playing);
      }),
    );
    _subscriptions.add(
      playback.controller.onCurrentDurationChanged.listen((duration) {
        if (!mounted) return;
        setState(() => _position = duration);
      }),
    );
    _subscriptions.add(
      playback.controller.onCompletion.listen((_) {
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
          _position = 0;
        });
        unawaited(
          playback.controller.seekTo(0).then((_) {
            // A last duration update may still arrive after the completion.
            if (mounted) setState(() => _position = 0);
          }),
        );
      }),
    );

    unawaited(_restoreState(playback));
  }

  /// Restores duration and position, which are already known when the player
  /// was prepared by a previous instance of this widget.
  Future<void> _restoreState(AudioPlayback playback) async {
    await playback.ready;
    if (!mounted) return;
    final position = await playback.controller.getDuration(
      DurationType.current,
    );
    if (!mounted) return;
    final started =
        playback.isPlaying ||
        playback.controller.playerState == PlayerState.paused;
    setState(() {
      _duration = playback.controller.maxDuration;
      _position = started && position > 0 ? position : 0;
      _isPlaying = playback.isPlaying;
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    final playback = _playback;
    if (playback != null) AudioPlaybackService.instance.detach(playback);
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final playback = _playback;
    if (playback == null) return;
    if (playback.isPlaying) {
      await playback.controller.pausePlayer();
      return;
    }
    await playback.ready;
    if (!mounted) return;
    await AudioPlaybackService.instance.play(playback);
    if (widget.message.senderId != null && widget.message.openedAt == null) {
      unawaited(_notifyMessageOpened());
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _duration <= 0 ? 0 : _duration - _position;
    final playback = _playback;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _playSlotWidth,
              child: GestureDetector(
                onTap: () => unawaited(_togglePlayback()),
                child: ColoredBox(
                  color: Colors.transparent,
                  child: FaIcon(
                    _isPlaying
                        ? FontAwesomeIcons.solidCirclePause
                        : FontAwesomeIcons.solidCirclePlay,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: _waveWidth,
              height: _waveHeight,
              child: Stack(
                children: [
                  if (playback != null)
                    AudioFileWaveforms(
                      // Rebuilds the waveform once the extraction finished so
                      // the complete waveform appears at once.
                      key: ValueKey(playback.waveformData.isNotEmpty),
                      playerController: playback.controller,
                      waveformData: playback.waveformData,
                      playerWaveStyle: _waveStyle,
                      // The whole waveform stays in place, only the already
                      // played part changes its color.
                      waveformType: WaveformType.fitWidth,
                      // Show the waveform right away instead of growing it in
                      // wave by wave while it is extracted.
                      continuousWaveform: false,
                      animationDuration: Duration.zero,
                      size: Size(_waveWidth, _waveHeight),
                    ),
                  if (_showCursor)
                    Positioned(
                      top: (_waveHeight - _cursorHeight) / 2,
                      height: _cursorHeight,
                      left: (_progress * (_waveWidth - _cursorWidth)).clamp(
                        0.0,
                        _waveWidth - _cursorWidth,
                      ),
                      child: IgnorePointer(
                        child: Container(
                          width: _cursorWidth,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            SizedBox(
              width: _playSlotWidth,
              child: Text(
                formatMsToMinSec(remaining),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (widget.trailing != null)
              SizedBox(
                width: _waveWidth,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: widget.trailing,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _notifyMessageOpened() async {
    final senderId = widget.message.senderId;
    if (senderId == null) return;
    final messageIds = [widget.message.messageId];
    await NativeNotificationService.cancelNotifications(messageIds);
    try {
      await RustApi.notifyMessagesOpened(
        contactId: senderId,
        messageIds: messageIds,
      );
    } finally {
      await NativeNotificationService.cancelNotifications(messageIds);
    }
  }
}

String formatMsToMinSec(int milliseconds) {
  final d = Duration(milliseconds: milliseconds);
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
