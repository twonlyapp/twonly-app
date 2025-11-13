import 'dart:async';
import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:drift/drift.dart' show Value;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/camera_send_to_view.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({
    required this.group,
    required this.quotesMessage,
    required this.textFieldFocus,
    required this.onMessageSend,
    super.key,
  });

  final Group group;
  final FocusNode textFieldFocus;
  final Message? quotesMessage;
  final VoidCallback onMessageSend;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

enum RecordingState { none, recording, finished }

class _MessageInputState extends State<MessageInput> {
  late final TextEditingController _textFieldController;
  late final RecorderController recorderController;
  final bool isApple = Platform.isIOS;
  bool _emojiShowing = false;
  RecordingState _recordingState = RecordingState.none;

  Future<void> _sendMessage() async {
    if (_textFieldController.text == '') return;

    await insertAndSendTextMessage(
      widget.group.groupId,
      _textFieldController.text,
      widget.quotesMessage?.messageId,
    );

    _textFieldController.clear();
    widget.onMessageSend();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _textFieldController = TextEditingController();
    if (widget.group.draftMessage != null) {
      _textFieldController.text = widget.group.draftMessage!;
    }
    widget.textFieldFocus.addListener(_handleTextFocusChange);
    _initializeControllers();
  }

  @override
  void dispose() {
    widget.textFieldFocus.removeListener(_handleTextFocusChange);
    widget.textFieldFocus.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
  }

  void _handleTextFocusChange() {
    if (widget.textFieldFocus.hasFocus) {
      setState(() {
        _emojiShowing = false;
      });
    }
  }

  Future<void> _stopAudioRecording() async {
    await HapticFeedback.heavyImpact();
    setState(() {
      _recordingState = RecordingState.none;
    });

    final audioTmpPath = await recorderController.stop();

    if (audioTmpPath == null) return;

    final mediaFileService = await initializeMediaUpload(
      MediaType.audio,
      null,
    );

    if (mediaFileService == null) return;

    File(audioTmpPath)
      ..copySync(mediaFileService.originalPath.path)
      ..deleteSync();

    await insertMediaFileInMessagesTable(
      mediaFileService,
      [widget.group.groupId],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: 10,
            left: 10,
            top: 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.color.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      if (_recordingState != RecordingState.recording)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _emojiShowing = !_emojiShowing;
                              if (_emojiShowing) {
                                widget.textFieldFocus.unfocus();
                              } else {
                                widget.textFieldFocus.requestFocus();
                              }
                            });
                          },
                          child: ColoredBox(
                            color: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 8,
                                left: 12,
                                right: 8,
                              ),
                              child: FaIcon(
                                size: 20,
                                _emojiShowing
                                    ? FontAwesomeIcons.keyboard
                                    : FontAwesomeIcons.faceSmile,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: (_recordingState == RecordingState.recording)
                            ? AudioWaveforms(
                                enableGesture: true,
                                size: Size(
                                  MediaQuery.of(context).size.width / 2,
                                  50,
                                ),
                                recorderController: recorderController,
                                waveStyle: WaveStyle(
                                  waveColor: isDarkMode(context)
                                      ? Colors.white
                                      : Colors.black,
                                  extendWaveform: true,
                                  showMiddleLine: false,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: context.color.surfaceContainer,
                                ),
                                padding: const EdgeInsets.only(left: 18),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 15),
                              )
                            : TextField(
                                controller: _textFieldController,
                                focusNode: widget.textFieldFocus,
                                keyboardType: TextInputType.multiline,
                                maxLines: 4,
                                minLines: 1,
                                onChanged: (value) async {
                                  setState(() {});
                                  await twonlyDB.groupsDao.updateGroup(
                                    widget.group.groupId,
                                    GroupsCompanion(
                                      draftMessage:
                                          Value(_textFieldController.text),
                                    ),
                                  );
                                },
                                onSubmitted: (_) {
                                  _sendMessage();
                                },
                                style: const TextStyle(fontSize: 17),
                                decoration: InputDecoration(
                                  hintText: context.lang.chatListDetailInput,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                              ),
                      ),
                      if (_textFieldController.text == '')
                        GestureDetector(
                          onLongPressStart: (a) async {
                            if (!await Permission.microphone.isGranted) {
                              final statuses = await [
                                Permission.microphone,
                              ].request();
                              if (statuses[Permission.microphone]!
                                  .isPermanentlyDenied) {
                                await openAppSettings();
                                return;
                              }
                              if (!await Permission.microphone.isGranted) {
                                return;
                              }
                            }
                            setState(() {
                              _recordingState = RecordingState.recording;
                            });
                            await HapticFeedback.heavyImpact();
                            final audioTmpPath =
                                '${(await getApplicationCacheDirectory()).path}/recording.m4a';
                            unawaited(
                              recorderController.record(
                                path: audioTmpPath,
                              ),
                            );
                          },
                          onLongPressCancel: () async {
                            final path = await recorderController.stop();
                            if (path == null) return;
                            if (File(path).existsSync()) {
                              File(path).deleteSync();
                            }
                            setState(() {
                              _recordingState = RecordingState.none;
                            });
                          },
                          onLongPressEnd: (a) => _stopAudioRecording(),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (_recordingState == RecordingState.recording)
                                Positioned.fill(
                                  top: -20,
                                  left: -25,
                                  bottom: -20,
                                  right: -20,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(90),
                                    ),
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                              ColoredBox(
                                color: Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 8,
                                    left: 8,
                                    right: 12,
                                  ),
                                  child: FaIcon(
                                    size: 20,
                                    color: (_recordingState ==
                                            RecordingState.recording)
                                        ? Colors.white
                                        : null,
                                    (_recordingState == RecordingState.none)
                                        ? FontAwesomeIcons.microphone
                                        : (_recordingState ==
                                                RecordingState.recording)
                                            ? FontAwesomeIcons.stop
                                            : FontAwesomeIcons.play,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_textFieldController.text != '')
                IconButton(
                  padding: const EdgeInsets.all(15),
                  icon: FaIcon(
                    color: context.color.primary,
                    FontAwesomeIcons.solidPaperPlane,
                  ),
                  onPressed: _sendMessage,
                )
              else
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.camera),
                  padding: const EdgeInsets.all(15),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return CameraSendToView(widget.group);
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        Offstage(
          offstage: !_emojiShowing,
          child: EmojiPicker(
            textEditingController: _textFieldController,
            onEmojiSelected: (category, emoji) {
              setState(() {});
            },
            onBackspacePressed: () {
              setState(() {});
            },
            config: Config(
              height: 300,
              locale: Localizations.localeOf(context),
              viewOrderConfig: const ViewOrderConfig(
                top: EmojiPickerItem.searchBar,
                // middle: EmojiPickerItem.emojiView,
                bottom: EmojiPickerItem.categoryBar,
              ),
              emojiTextStyle:
                  TextStyle(fontSize: 24 * (Platform.isIOS ? 1.2 : 1)),
              emojiViewConfig: EmojiViewConfig(
                backgroundColor: context.color.surfaceContainer,
              ),
              searchViewConfig: SearchViewConfig(
                backgroundColor: context.color.surfaceContainer,
                buttonIconColor: Colors.white,
              ),
              categoryViewConfig: CategoryViewConfig(
                backgroundColor: context.color.surfaceContainer,
                dividerColor: Colors.white,
                indicatorColor: context.color.primary,
                iconColorSelected: context.color.primary,
                iconColor: context.color.secondary,
              ),
              bottomActionBarConfig: BottomActionBarConfig(
                backgroundColor: context.color.surfaceContainer,
                buttonColor: context.color.surfaceContainer,
                buttonIconColor: context.color.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
