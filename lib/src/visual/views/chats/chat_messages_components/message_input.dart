import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/stickers/sticker.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';
import 'package:twonly/src/visual/components/sticker_picker.dart';
import 'package:twonly/src/visual/views/camera/camera_send_to.view.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/bottom_sheets/share_additional.bottom_sheet.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_audio_entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_input_components/ask_for_friend_promotions.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_input_components/sparks.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_input_components/user_discovery_manual_approval.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/typing_indicator.dart';
import 'package:twonly/src/visual/views/contact/contact_components/restore_flame.comp.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({
    required this.group,
    required this.quotesMessage,
    required this.textFieldFocus,
    required this.onMessageSend,
    required this.onEmojiVisibilityChanged,
    required this.composing,
    super.key,
  });

  final Group group;
  final FocusNode textFieldFocus;
  final Message? quotesMessage;
  final VoidCallback onMessageSend;
  final ValueChanged<bool> onEmojiVisibilityChanged;

  /// Published so the chat-open heartbeat can stay quiet while the typing
  /// announcement is already covering this conversation.
  final ValueNotifier<bool> composing;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

/// How long after the last keystroke the composer still counts as being typed
/// in. Longer than [typingIndicatorInterval] so the indicator survives the gap
/// between two announcements.
const _composingIdleTimeout = Duration(seconds: 6);

/// How far up the finger has to travel before it sits on the lock pill that
/// floats above the microphone. The pill is drawn 120px above the button and
/// is 60px tall, so its lower edge is roughly this far from the grab point.
const _lockHintOffset = 70.0;

/// How far up the finger has to travel for the recording to actually latch.
const _lockOffset = 100.0;

enum RecordingState { none, recording, finished }

class _MessageInputState extends State<MessageInput>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TextEditingController _textFieldController;
  late final RecorderController recorderController;
  final bool isApple = Platform.isIOS;
  bool _emojiShowing = false;
  bool _stickerShowing = false;
  bool _switchingToSystemKeyboard = false;
  double _emojiPickerHeight = 300;
  bool _showSparks = false;
  bool _audioRecordingLock = false;
  bool _overLockIcon = false;
  int _currentDuration = 0;
  double _cancelSlideOffset = 0;
  Offset _recordingOffset = Offset.zero;
  RecordingState _recordingState = RecordingState.none;
  Timer? _nextTypingIndicator;
  DateTime? _lastTextChangeTime;
  int? _contactId;
  Timer? _recordingTimer;
  Timer? _keyboardTransitionTimer;
  DateTime? _recordingStartTime;

  /// Pulses the microphone icon while a recording is running so the composer
  /// reads as live even when the waveform is off screen.
  late final AnimationController _recordingBlink;

  void _sendMessage() {
    final text = _textFieldController.text;
    if (text == '') return;
    final quoteMessageId = widget.quotesMessage?.messageId;

    // Emptying the composer is not allowed to wait on the bridge: Rust commits
    // the message row before it starts delivering, so the bubble is already on
    // its way into the chat list while this call is still running.
    _textFieldController.clear();
    widget.onMessageSend();
    setState(() {});

    unawaitedRustCall(
      RustApi.insertAndSendText(
        groupId: widget.group.groupId,
        text: text,
        quoteMessageId: quoteMessageId,
      ),
      'insertAndSendText',
    );
  }

  void _sendSticker(LocalSticker sticker) {
    final quoteMessageId = widget.quotesMessage?.messageId;
    widget.onMessageSend();
    unawaitedRustCall(
      StickerService.send(
        groupId: widget.group.groupId,
        sticker: sticker,
        quoteMessageId: quoteMessageId,
      ),
      'sendSticker',
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _textFieldController = TextEditingController();
    _textFieldController.addListener(_handleTextChange);
    if (widget.group.draftMessage != null) {
      _textFieldController.text = widget.group.draftMessage!;
    }
    widget.textFieldFocus.addListener(_handleTextFocusChange);
    if (userService.currentUser.typingIndicators) {
      _nextTypingIndicator = Timer.periodic(typingIndicatorInterval, (_) {
        final composing = _isComposing;
        widget.composing.value = composing;
        if (composing) {
          unawaitedRustCall(
            RustApi.sendTyping(
              groupId: widget.group.groupId,
              isTyping: true,
            ),
            'sendTyping',
          );
        }
      });
    }
    _initializeControllers();
    _loadContactId();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textFieldController.removeListener(_handleTextChange);
    widget.textFieldFocus.removeListener(_handleTextFocusChange);
    widget.textFieldFocus.dispose();
    _recordingTimer?.cancel();
    _keyboardTransitionTimer?.cancel();
    _recordingBlink.dispose();
    recorderController.dispose();
    _nextTypingIndicator?.cancel();
    widget.composing.value = false;

    // Persist draft message on close
    final draftText = _textFieldController.text;
    unawaited(
      twonlyDB.groupsDao.updateGroup(
        widget.group.groupId,
        GroupsCompanion(
          draftMessage: Value(draftText.isEmpty ? null : draftText),
        ),
      ),
    );
    _textFieldController.dispose();

    super.dispose();
  }

  void _initializeControllers() {
    recorderController = RecorderController();
    _recordingBlink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: 0.25,
    );
  }

  /// Whether the composer counts as being typed in right now.
  ///
  /// The idle window outlives one announcement interval, so a pause to think
  /// mid-sentence does not drop the indicator on the other side.
  bool get _isComposing =>
      widget.textFieldFocus.hasFocus &&
      _lastTextChangeTime != null &&
      clock.now().difference(_lastTextChangeTime!) <= _composingIdleTimeout;

  void _handleTextChange() {
    final now = clock.now();
    // The periodic announcement is what keeps the indicator alive, but at its
    // cadence the first keystroke would take seconds to reach the other side.
    // That one is announced directly and the timer carries it from there.
    final wasIdle =
        _lastTextChangeTime == null ||
        now.difference(_lastTextChangeTime!) > typingIndicatorInterval;
    _lastTextChangeTime = now;
    if (wasIdle &&
        userService.currentUser.typingIndicators &&
        widget.textFieldFocus.hasFocus) {
      widget.composing.value = true;
      unawaitedRustCall(
        RustApi.sendTyping(groupId: widget.group.groupId, isTyping: true),
        'sendTyping',
      );
    }
  }

  void _handleTextFocusChange() {
    if (widget.textFieldFocus.hasFocus &&
        _emojiShowing &&
        !_switchingToSystemKeyboard) {
      _showSystemKeyboard();
    }
  }

  @override
  void didChangeMetrics() {
    if (!mounted || !_switchingToSystemKeyboard) return;
    final keyboardHeight = _currentKeyboardHeight();
    if (keyboardHeight < _emojiPickerHeight * 0.8) return;

    _keyboardTransitionTimer?.cancel();
    _keyboardTransitionTimer = Timer(
      const Duration(milliseconds: 80),
      _finishSystemKeyboardTransition,
    );
  }

  void _toggleKeyboard() {
    if (_emojiShowing) {
      _showSystemKeyboard();
    } else {
      _showEmojiPicker();
    }
  }

  void _showEmojiPicker() {
    _keyboardTransitionTimer?.cancel();
    final keyboardHeight = _currentKeyboardHeight();
    setState(() {
      _switchingToSystemKeyboard = false;
      if (keyboardHeight > 0) {
        _emojiPickerHeight = keyboardHeight;
      }
      _emojiShowing = true;
      _stickerShowing = false;
    });
    widget.onEmojiVisibilityChanged(true);
    widget.textFieldFocus.unfocus();
  }

  double _currentKeyboardHeight() {
    final view = View.of(context);
    final keyboardHeight = view.viewInsets.bottom / view.devicePixelRatio;
    final safeAreaBottom = view.viewPadding.bottom / view.devicePixelRatio;
    return (keyboardHeight - safeAreaBottom).clamp(0, double.infinity);
  }

  void _showSystemKeyboard() {
    if (_switchingToSystemKeyboard) return;
    setState(() => _switchingToSystemKeyboard = true);
    widget.textFieldFocus.requestFocus();

    // Some platforms only report the final keyboard inset. The fallback still
    // performs a single picker/keyboard swap instead of following every inset
    // animation frame.
    _keyboardTransitionTimer?.cancel();
    _keyboardTransitionTimer = Timer(
      const Duration(milliseconds: 700),
      _finishSystemKeyboardTransition,
    );
  }

  void _finishSystemKeyboardTransition() {
    if (!mounted || !_switchingToSystemKeyboard) return;
    _keyboardTransitionTimer?.cancel();
    setState(() {
      _switchingToSystemKeyboard = false;
      _emojiShowing = false;
    });
    widget.onEmojiVisibilityChanged(false);
  }

  Future<void> _startAudioRecording() async {
    if (!await Permission.microphone.isGranted) {
      final statuses = await [
        Permission.microphone,
      ].request();
      if (statuses[Permission.microphone]!.isPermanentlyDenied) {
        await openAppSettings();
        return;
      }
      if (!await Permission.microphone.isGranted) {
        return;
      }
    }
    setState(() {
      _recordingState = RecordingState.recording;
      _currentDuration = 0;
      _overLockIcon = false;
    });
    _recordingBlink.repeat(reverse: true);
    _recordingStartTime = clock.now();
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (!mounted) return;
      setState(() {
        if (_recordingStartTime != null) {
          _currentDuration = clock
              .now()
              .difference(_recordingStartTime!)
              .inMilliseconds;
        }
      });
    });
    await HapticFeedback.heavyImpact();
    final audioTmpPath = '${AppEnvironment.cacheDir}/recording.m4a';
    unawaited(
      recorderController.record(
        path: audioTmpPath,
      ),
    );
  }

  Future<void> _stopAudioRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingBlink.stop();
    await HapticFeedback.heavyImpact();
    setState(() {
      _audioRecordingLock = false;
      _overLockIcon = false;
      _cancelSlideOffset = 0;
      _recordingState = RecordingState.none;
    });

    final audioTmpPath = await recorderController.stop();

    if (audioTmpPath == null) return;

    final mediaId = await RustApi.initializeMediaUpload(
      mediaType: MediaType.audio.name,
      isDraftMedia: false,
    );
    final mediaFileService = await MediaFileService.fromMediaId(mediaId);

    if (mediaFileService == null) return;

    File(audioTmpPath)
      ..copySync(mediaFileService.originalPath.path)
      ..deleteSync();

    await RustApi.sendMediaToGroups(
      mediaId: mediaFileService.mediaFile.mediaId,
      groupIds: [widget.group.groupId],
      widgetOnly: false,
    );
  }

  Future<void> _cancelAudioRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingBlink.stop();
    setState(() {
      _audioRecordingLock = false;
      _overLockIcon = false;
      _cancelSlideOffset = 0;
      _recordingState = RecordingState.none;
    });
    final path = await recorderController.stop();
    if (path == null) return;
    if (File(path).existsSync()) {
      File(path).deleteSync();
    }
  }

  Future<void> _showAdditionalShareModal(BuildContext context) async {
    setState(() {
      _showSparks = false;
    });
    if (widget.group.isDirectChat) {
      final members = await twonlyDB.groupsDao.getGroupContact(
        widget.group.groupId,
      );
      if (members.isNotEmpty) {
        await twonlyDB.contactsDao.updateContact(
          members.first.userId,
          const ContactsCompanion(
            askForFriendPromotions: Value(false),
          ),
        );
      }
    }
    if (!context.mounted) return;
    // ignore: inference_failure_on_function_invocation
    await showModalBottomSheet(
      context: context,
      backgroundColor: context.color.surface,
      builder: (context) {
        return ShareAdditionalView(
          group: widget.group,
        );
      },
    );
  }

  Future<void> _loadContactId() async {
    if (widget.group.isDirectChat) {
      final members = await twonlyDB.groupsDao.getGroupContact(
        widget.group.groupId,
      );
      if (members.isNotEmpty && mounted) {
        setState(() {
          _contactId = members.first.userId;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UserDiscoveryManualApprovalComp(group: widget.group),
        AskForFriendPromotionsComp(
          group: widget.group,
          onHighlightChanged: (highlight) {
            if (!mounted) return;
            setState(() {
              _showSparks = highlight;
            });
          },
        ),
        if (_contactId != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: context.color.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: RestoreFlameComp(
              contactId: _contactId!,
              flameOnRightSide: true,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.color.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      if (_recordingState != RecordingState.recording)
                        GestureDetector(
                          onTap: _toggleKeyboard,
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
                                size: _emojiShowing ? 18 : 20,
                                _emojiShowing
                                    ? FontAwesomeIcons.keyboard
                                    : FontAwesomeIcons.faceSmile,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Stack(
                          children: [
                            TextField(
                              controller: _textFieldController,
                              focusNode: widget.textFieldFocus,
                              textCapitalization: TextCapitalization.sentences,
                              keyboardType: TextInputType.multiline,
                              showCursor:
                                  _recordingState != RecordingState.recording,
                              maxLines: 4,
                              minLines: 1,
                              onChanged: (value) {
                                setState(() {});
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
                            if (_recordingState == RecordingState.recording)
                              Container(
                                decoration: BoxDecoration(
                                  color: context.color.surfaceContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 14,
                                        bottom: 14,
                                        left: 12,
                                        right: 8,
                                      ),
                                      child: FadeTransition(
                                        opacity: _recordingBlink,
                                        child: FaIcon(
                                          FontAwesomeIcons.microphone,
                                          size: 20,
                                          color: context.appColor(
                                            AppColor.recording,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      formatMsToMinSec(
                                        _currentDuration,
                                      ),
                                      style: TextStyle(
                                        color: context.color.onSurface,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (!_audioRecordingLock) ...[
                                      SizedBox(
                                        width: (100 - _cancelSlideOffset) % 101,
                                      ),
                                      Text(
                                        context.lang.voiceMessageSlideToCancel,
                                      ),
                                    ] else ...[
                                      Expanded(
                                        child: Container(),
                                      ),
                                      GestureDetector(
                                        onTap: _cancelAudioRecording,
                                        child: Text(
                                          context.lang.voiceMessageCancel,
                                          style: TextStyle(
                                            color: context.appColor(
                                              AppColor.recording,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_textFieldController.text == '' &&
                          _recordingState == RecordingState.none)
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.camera),
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
                      if (_textFieldController.text == '')
                        GestureDetector(
                          onLongPressMoveUpdate: (details) {
                            if (_audioRecordingLock) return;
                            final upwards =
                                _recordingOffset.dy - details.localPosition.dy;
                            // Nudge once when the finger reaches the lock, so
                            // it is clear the gesture will latch before the
                            // user commits to it.
                            if (upwards >= _lockHintOffset && !_overLockIcon) {
                              _overLockIcon = true;
                              HapticFeedback.selectionClick();
                            } else if (upwards < _lockHintOffset &&
                                _overLockIcon) {
                              _overLockIcon = false;
                            }
                            if (upwards >= _lockOffset) {
                              HapticFeedback.heavyImpact();
                              setState(() {
                                _audioRecordingLock = true;
                              });
                            }
                            if (_recordingOffset.dx -
                                        details.localPosition.dx >=
                                    90 &&
                                _recordingState == RecordingState.recording) {
                              _recordingState = RecordingState.none;
                              HapticFeedback.heavyImpact();
                              _cancelAudioRecording();
                            }

                            setState(() {
                              final a =
                                  _recordingOffset.dx -
                                  details.localPosition.dx;
                              if (a > 0 && a <= 90) {
                                _cancelSlideOffset =
                                    _recordingOffset.dx -
                                    details.localPosition.dx;
                              }
                            });
                          },
                          onLongPressStart: (a) {
                            _recordingOffset = a.localPosition;
                            _startAudioRecording();
                          },
                          onLongPressCancel: _cancelAudioRecording,
                          onLongPressEnd: (a) {
                            if (_recordingState != RecordingState.recording) {
                              return;
                            }
                            if (!_audioRecordingLock) {
                              _stopAudioRecording();
                            }
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (_recordingState == RecordingState.recording &&
                                  !_audioRecordingLock)
                                Positioned.fill(
                                  top: -120,
                                  left: -5,
                                  child: Align(
                                    alignment: AlignmentGeometry.topCenter,
                                    child: Container(
                                      padding: const EdgeInsets.only(top: 13),
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          90,
                                        ),
                                        color: context.color.surface,
                                      ),
                                      child: const Center(
                                        child: Column(
                                          children: [
                                            FaIcon(
                                              FontAwesomeIcons.lock,
                                              size: 16,
                                            ),
                                            SizedBox(height: 5),
                                            FaIcon(
                                              FontAwesomeIcons.angleUp,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_recordingState == RecordingState.recording &&
                                  !_audioRecordingLock)
                                Positioned.fill(
                                  top: -20,
                                  left: -25,
                                  bottom: -20,
                                  right: -20,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: context.appColor(
                                        AppColor.recording,
                                      ),
                                      borderRadius: BorderRadius.circular(90),
                                    ),
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                              if (!_audioRecordingLock)
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
                                      color:
                                          (_recordingState ==
                                              RecordingState.recording)
                                          ? context.color.onError
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
              if (_textFieldController.text != '' || _audioRecordingLock)
                IconButton(
                  padding: const EdgeInsets.all(15),
                  icon: FaIcon(
                    color: context.color.primary,
                    FontAwesomeIcons.solidPaperPlane,
                  ),
                  onPressed: _audioRecordingLock
                      ? _stopAudioRecording
                      : _sendMessage,
                )
              else
                SparksWidget(
                  animate: _showSparks,
                  child: IconButton(
                    icon: const FaIcon(FontAwesomeIcons.plus),
                    padding: const EdgeInsets.all(15),
                    onPressed: () => _showAdditionalShareModal(context),
                  ),
                ),
            ],
          ),
        ),
        Offstage(
          offstage: !_emojiShowing,
          child: EmojiPicker(
            alternateView: _stickerShowing
                ? StickerPicker(
                    onEmojiPressed: () {
                      setState(() => _stickerShowing = false);
                    },
                    onStickerSelected: _sendSticker,
                  )
                : null,
            textEditingController: _textFieldController,
            onEmojiSelected: (category, emoji) {
              setState(() {});
            },
            onBackspacePressed: () {
              setState(() {});
            },
            config: Config(
              height: _emojiPickerHeight,
              locale: Localizations.localeOf(context),
              emojiTextStyle: TextStyle(
                fontSize: 24 * (Platform.isIOS ? 1.2 : 1),
              ),
              emojiViewConfig: EmojiViewConfig(
                backgroundColor: context.color.surfaceContainer,
                recentsLimit: 40,
              ),
              searchViewConfig: SearchViewConfig(
                backgroundColor: context.color.surfaceContainer,
                buttonIconColor: context.color.onSurface,
              ),
              categoryViewConfig: CategoryViewConfig(
                backgroundColor: context.color.surfaceContainer,
                indicatorColor: context.color.primary,
                iconColorSelected: context.color.primary,
                iconColor: context.color.secondary,
              ),
              bottomActionBarConfig: BottomActionBarConfig(
                backgroundColor: context.color.surfaceContainer,
                buttonColor: context.color.surfaceContainer,
                buttonIconColor: context.color.secondary,
                stickerButtonLabel: context.lang.sticker,
                onStickerButtonPressed: () {
                  setState(() => _stickerShowing = true);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
