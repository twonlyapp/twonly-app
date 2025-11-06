import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/views/chats/chat_messages_components/entries/common.dart';
import 'package:twonly/src/views/chats/chat_messages_components/entries/friendly_message_time.comp.dart';
import 'package:twonly/src/views/chats/chat_messages_components/message_send_state_icon.dart';
import 'package:twonly/src/views/components/better_text.dart';

class ChatAudioEntry extends StatelessWidget {
  const ChatAudioEntry({
    required this.message,
    required this.nextMessage,
    required this.mediaService,
    required this.prevMessage,
    required this.borderRadius,
    required this.userIdToContact,
    required this.minWidth,
    super.key,
  });

  final Message message;
  final MediaFileService mediaService;
  final Message? nextMessage;
  final Message? prevMessage;
  final Map<int, Contact>? userIdToContact;
  final BorderRadius borderRadius;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    if (!mediaService.tempPath.existsSync() &&
        !mediaService.originalPath.existsSync()) {
      return Container(); // media file was purged
    }
    final info = getBubbleInfo(
      context,
      message,
      nextMessage,
      prevMessage,
      userIdToContact,
      minWidth,
    );

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
        minWidth: 250,
      ),
      padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6, right: 10),
      decoration: BoxDecoration(
        color: info.color,
        borderRadius: borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info.displayUserName != '')
            Text(
              info.displayUserName,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (info.text != '')
                Expanded(
                  child: BetterText(text: info.text, textColor: info.textColor),
                )
              else ...[
                if (mediaService.mediaFile.downloadState ==
                        DownloadState.ready ||
                    mediaService.mediaFile.downloadState == null)
                  mediaService.tempPath.existsSync()
                      ? InChatAudioPlayer(
                          path: mediaService.tempPath.path,
                          message: message,
                        )
                      : (mediaService.originalPath.existsSync())
                          ? InChatAudioPlayer(
                              path: mediaService.originalPath.path,
                              message: message,
                            )
                          : Container()
                else
                  MessageSendStateIcon([message], [mediaService.mediaFile]),
              ],
              if (info.displayTime || message.modifiedAt != null)
                FriendlyMessageTime(message: message),
            ],
          ),
        ],
      ),
    );
  }
}

class InChatAudioPlayer extends StatefulWidget {
  const InChatAudioPlayer({
    required this.path,
    required this.message,
    super.key,
  });

  final String path;
  final Message message;

  @override
  State<InChatAudioPlayer> createState() => _InChatAudioPlayerState();
}

class _InChatAudioPlayerState extends State<InChatAudioPlayer> {
  final PlayerController _playerController = PlayerController();
  int _displayDuration = 0;
  int _maxDuration = 0;

  @override
  void initState() {
    super.initState();
    _playerController
      ..preparePlayer(path: widget.path)
      ..setFinishMode(finishMode: FinishMode.pause);

    _playerController.onCompletion.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playerController.seekTo(0);
        });
      }
    });

    _playerController.onCurrentDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _displayDuration = _maxDuration - duration;
        });
      }
    });
    initAsync();
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  Future<void> initAsync() async {
    _displayDuration = await _playerController.getDuration(DurationType.max);
    _maxDuration = _displayDuration;
    if (!mounted) return;
    setState(() {});
  }

  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (_isPlaying) {
                    _playerController.pausePlayer();
                  } else {
                    _playerController.startPlayer();
                    if (widget.message.senderId != null &&
                        widget.message.openedAt == null) {
                      notifyContactAboutOpeningMessage(
                        widget.message.senderId!,
                        [widget.message.messageId],
                      );
                    }
                  }
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
                child: Container(
                  padding: EdgeInsets.only(
                    left: _isPlaying ? 2 : 0,
                    top: 4,
                    bottom: 4,
                  ),
                  color: Colors.transparent,
                  child: FaIcon(
                    _isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                formatMsToMinSec(_displayDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        AudioFileWaveforms(
          playerController: _playerController,
          size: const Size(150, 40),
        ),
      ],
    );
  }
}

String formatMsToMinSec(int milliseconds) {
  final d = Duration(milliseconds: milliseconds);
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
