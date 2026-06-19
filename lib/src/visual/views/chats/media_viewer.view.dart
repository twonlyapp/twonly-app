import 'dart:async';
import 'dart:collection';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:mutex/mutex.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart'
    show DownloadState, MediaType;
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/services/api/mediafiles/download.api.dart';
import 'package:twonly/src/services/api/messages.api.dart';
import 'package:twonly/src/services/api/utils.api.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/background.notifications.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/elements/my_icon_button.element.dart';
import 'package:twonly/src/visual/helpers/media_view_sizing.helper.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';
import 'package:twonly/src/visual/views/camera/camera_send_to.view.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/additional_message_content.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/media_content_renderer.comp.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/media_viewer_message_input.comp.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/reaction_buttons.comp.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/twonly_present_overlay.comp.dart';
import 'package:video_player/video_player.dart';

class MediaViewerView extends StatefulWidget {
  const MediaViewerView(this.group, {super.key, this.initialMessage});
  final Group group;

  final Message? initialMessage;
  @override
  State<MediaViewerView> createState() => _MediaViewerViewState();
}

class _MediaViewerViewState extends State<MediaViewerView> {
  Timer? nextMediaTimer;
  Timer? progressTimer;

  bool showShortReactions = false;
  double mediaViewerDistanceFromBottom = 0;

  // current image related
  VideoPlayerController? videoController;

  VoidCallback? _videoListener;

  MediaFileService? currentMedia;
  Message? currentMessage;

  DateTime? canBeSeenUntil;
  final ValueNotifier<double> progress = ValueNotifier(0);
  bool showSendTextMessageInput = false;
  double maxBottomInset = 0;
  DateTime? _lastTimeInputClosed;
  final GlobalKey mediaWidgetKey = GlobalKey();

  bool imageSaved = false;
  bool imageSaving = false;
  bool displayTwonlyPresent = false;
  bool _showDownloadingLoader = false;
  late String _currentMediaSender;
  final emojiKey = GlobalKey<EmojiFloatWidgetState>();

  StreamSubscription<MediaFile?>? downloadStateListener;

  List<Message> allMediaFiles = [];
  StreamSubscription<List<Message>>? _subscription;
  TextEditingController textMessageController = TextEditingController();

  final HashSet<String> _alreadyOpenedMediaIds = HashSet();

  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _currentMediaSender = widget.group.groupName;

    if (widget.initialMessage != null) {
      allMediaFiles = [widget.initialMessage!];
    }

    listenForUnopenedMedia(true);
  }

  @override
  void dispose() {
    nextMediaTimer?.cancel();
    progressTimer?.cancel();
    _subscription?.cancel();
    downloadStateListener?.cancel();
    progress.dispose();

    ScreenProtector.preventScreenshotOff();

    _disposeVideoController();

    // Persist draft message on close
    final draftText = textMessageController.text;
    unawaited(
      twonlyDB.groupsDao.updateGroup(
        widget.group.groupId,
        GroupsCompanion(
          draftMessage: Value(draftText.isEmpty ? null : draftText),
        ),
      ),
    );
    textMessageController.dispose();

    super.dispose();
  }

  void _disposeVideoController() {
    final listener = _videoListener;
    final controller = videoController;
    _videoListener = null;
    videoController = null;
    if (listener != null) {
      controller?.removeListener(listener);
    }
    controller?.dispose();
  }

  final Mutex _messageUpdateLock = Mutex();

  bool _isViewActive() {
    return !AppState.isAppInBackground &&
        (ModalRoute.of(context)?.isCurrent ?? false);
  }

  Future<void> listenForUnopenedMedia(bool firstRun) async {
    _subscription = twonlyDB.messagesDao
        .watchMediaNotOpened(widget.group.groupId)
        .listen((messages) async {
          await _messageUpdateLock.protect(() async {
            for (final msg in messages) {
              if (_alreadyOpenedMediaIds.contains(msg.mediaId)) {
                continue;
              }
              if (msg.mediaId == null) {
                continue;
              }

              if (msg.mediaId == currentMedia?.mediaFile.mediaId) {
                // The update of the current Media in case of a download is done in loadAndDownloadCurrentMedia
                continue;
              }

              /// If the messages was already there just replace it and go to the next...

              final index = allMediaFiles.indexWhere(
                (m) => m.messageId == msg.messageId,
              );

              if (index >= 1) {
                allMediaFiles[index] = msg;
              } else if (index == -1) {
                // If the message does not exist, add it
                allMediaFiles.add(msg);
              }
            }
            if (allMediaFiles.length > 1) {
              if (widget.initialMessage == null &&
                  currentMedia == null &&
                  !_showDownloadingLoader) {
                allMediaFiles.sort(
                  (a, b) => a.createdAt.compareTo(b.createdAt),
                );
              } else {
                final upcoming = allMediaFiles.sublist(1)
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                allMediaFiles = [allMediaFiles.first, ...upcoming];
              }
            }
            if (mounted) setState(() {});
            if (firstRun) {
              firstRun = false;
              await loadAndDownloadCurrentMedia();
            }
          });
        });
  }

  Future<void> advanceToNextMediaOrExit() async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      /// Remove the current media file in case it is not set to unlimited
      if (currentMedia != null) {
        if (!imageSaved &&
            currentMedia!.mediaFile.displayLimitInMilliseconds != null) {
          currentMedia!.fullMediaRemoval();
        }
      }

      _disposeVideoController();

      if (!mounted) return;

      nextMediaTimer?.cancel();
      progressTimer?.cancel();

      if (allMediaFiles.isEmpty) {
        final group = await twonlyDB.groupsDao.getGroup(widget.group.groupId);
        if (mounted) {
          if (group != null &&
              group.draftMessage != null &&
              group.draftMessage != '') {
            context.replace(Routes.chatsMessages(group.groupId));
          } else {
            Navigator.pop(context);
          }
        }
      } else {
        await loadAndDownloadCurrentMedia();
      }
    } finally {
      if (mounted) _isTransitioning = false;
    }
  }

  Future<void> loadAndDownloadCurrentMedia({bool showTwonly = false}) async {
    if (!mounted || !context.mounted) return;
    if (allMediaFiles.isEmpty || allMediaFiles.first.mediaId == null) {
      return advanceToNextMediaOrExit();
    }

    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (e) {
      Log.error(e);
    }

    if (!mounted) return;

    setState(() {
      videoController = null;
      currentMedia = null;
      currentMessage = null;
      canBeSeenUntil = null;
      imageSaving = false;
      imageSaved = false;
      progress.value = 0;
      showSendTextMessageInput = false;
    });

    if (_isViewActive()) {
      unawaited(flutterLocalNotificationsPlugin.cancelAll());
    }

    final stream = twonlyDB.mediaFilesDao.watchMedia(
      allMediaFiles.first.mediaId!,
    );

    var downloadTriggered = false;

    await downloadStateListener?.cancel();
    downloadStateListener = stream.listen((updated) async {
      if (updated == null) {
        // Media file record no longer exists — skip to next or exit rather
        // than leaving the screen permanently black with no content/loader.
        await downloadStateListener?.cancel();
        await advanceToNextMediaOrExit();
        return;
      }
      if (updated.downloadState != DownloadState.ready) {
        setState(() {
          _showDownloadingLoader = true;
        });
        if (!downloadTriggered) {
          downloadTriggered = true;
          final mediaFile = await twonlyDB.mediaFilesDao.getMediaFileById(
            allMediaFiles.first.mediaId!,
          );
          if (mediaFile == null) {
            // DB record gone — skip to next or exit.
            await downloadStateListener?.cancel();
            await advanceToNextMediaOrExit();
            return;
          }
          await startDownloadMedia(mediaFile, true);
          unawaited(tryDownloadAllMediaFiles(force: true));
        }
        return;
      }

      await downloadStateListener?.cancel();
      try {
        await initializeAndDisplayCurrentMedia(showTwonly);
      } catch (e, st) {
        Log.error('initializeAndDisplayCurrentMedia failed: $e\n$st');
        await advanceToNextMediaOrExit();
      }
      // start downloading all the other possible missing media files.
    });
  }

  Future<void> initializeAndDisplayCurrentMedia(bool showTwonly) async {
    if (allMediaFiles.isEmpty) return;
    setState(() {
      _showDownloadingLoader = false;
    });
    final currentMediaLocal = await MediaFileService.fromMediaId(
      allMediaFiles.first.mediaId!,
    );
    if (currentMediaLocal == null || !mounted) return;

    if (currentMediaLocal.mediaFile.requiresAuthentication) {
      if (!showTwonly) {
        setState(() {
          displayTwonlyPresent = true;
        });
        return;
      }

      final isAuth = await authenticateUser(
        context.lang.mediaViewerAuthReason,
        force: false,
      );
      if (!mounted) return;

      if (!isAuth) {
        await advanceToNextMediaOrExit();
        if (mounted) {
          setState(() {
            displayTwonlyPresent = false;
          });
        }
        return;
      }
    }

    _alreadyOpenedMediaIds.add(allMediaFiles.first.mediaId!);
    currentMessage = allMediaFiles.removeAt(0);

    setState(() {
      displayTwonlyPresent = false;
    });

    await _updateSenderInfo();
    if (!mounted) return;

    await _notifyMessageOpened(currentMediaLocal);
    if (!mounted) return;

    if (!currentMediaLocal.tempPath.existsSync()) {
      Log.error('Temp media file not found...');
      await handleMediaError(currentMediaLocal.mediaFile);
      return advanceToNextMediaOrExit();
    }

    // The server can now delete the encrypted bytes, as the users has sucessfully opened it.
    unawaited(
      apiService.downloadDone(currentMediaLocal.mediaFile.downloadToken!),
    );

    if (currentMediaLocal.mediaFile.type == MediaType.video) {
      await _setupVideoPlayer(currentMediaLocal);
    } else {
      _setupImageTimer(currentMediaLocal);
    }

    if (mounted) {
      setState(() {
        currentMedia = currentMediaLocal;
      });
    }
  }

  Future<void> _updateSenderInfo() async {
    if (currentMessage == null || widget.group.isDirectChat) return;
    final sender = await twonlyDB.contactsDao.getContactById(
      currentMessage!.senderId!,
    );
    if (mounted && sender != null) {
      _currentMediaSender =
          '${getContactDisplayName(sender)} (${widget.group.groupName})';
    }
  }

  Future<void> _notifyMessageOpened(MediaFileService mediaLocal) async {
    if (currentMessage == null) return;
    var markAsOpenMessageIDs = [currentMessage!.messageId];

    if (userService.currentUser.automaticallyMarkEqualMediaFilesAsOpened &&
        mediaLocal.mediaFile.storedFileHash != null) {
      final messageIds = await twonlyDB.mediaFilesDao.getMessageIdsByMediaHash(
        mediaLocal.mediaFile.storedFileHash!,
        currentMessage!.senderId!,
      );

      if (!messageIds.contains(currentMessage!.messageId)) {
        Log.error(
          'Original message ID was not returned from `getMessageIdsByMediaHash`.',
        );
        messageIds.add(currentMessage!.messageId);
      }

      markAsOpenMessageIDs = messageIds;
    }

    await notifyContactAboutOpeningMessage(
      currentMessage!.senderId!,
      markAsOpenMessageIDs,
    );
  }

  Future<void> _setupVideoPlayer(MediaFileService mediaLocal) async {
    final controller = VideoPlayerController.file(
      mediaLocal.tempPath,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: mediaLocal.mediaFile.displayLimitInMilliseconds == null,
      ),
    );

    await controller.setLooping(
      mediaLocal.mediaFile.displayLimitInMilliseconds == null,
    );

    if (!mounted) {
      await controller.dispose();
      return;
    }

    await controller
        .initialize()
        .then((_) {
          if (!mounted || videoController != null) {
            controller.dispose();
            return;
          }

          void listener() {
            if (!mounted) return;
            final ctrl = videoController;
            if (ctrl == null) return;

            final duration = ctrl.value.duration.inSeconds;
            if (duration > 0) {
              progress.value = 1 - ctrl.value.position.inSeconds / duration;
            }

            if (mediaLocal.mediaFile.displayLimitInMilliseconds != null) {
              if (ctrl.value.position == ctrl.value.duration) {
                advanceToNextMediaOrExit();
              }
            }
          }

          _videoListener = listener;
          videoController = controller;
          controller
            ..addListener(listener)
            ..play();
        })
        .catchError((Object err, StackTrace st) {
          Log.error('Video player initialization error', err, st);
          return null;
        });
  }

  void _setupImageTimer(MediaFileService mediaLocal) {
    if (mediaLocal.mediaFile.displayLimitInMilliseconds != null) {
      canBeSeenUntil = clock.now().add(
        Duration(
          milliseconds: mediaLocal.mediaFile.displayLimitInMilliseconds!,
        ),
      );
      if (mounted) {
        startProgressTimer();
      }
    }
  }

  void startProgressTimer() {
    nextMediaTimer?.cancel();
    progressTimer?.cancel();
    if (canBeSeenUntil != null) {
      nextMediaTimer = Timer(canBeSeenUntil!.difference(clock.now()), () {
        if (context.mounted) {
          advanceToNextMediaOrExit();
        }
      });
      progressTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
        final mediaFile = currentMedia?.mediaFile;
        if (mediaFile == null) return;
        if (mediaFile.displayLimitInMilliseconds == null ||
            canBeSeenUntil == null) {
          return;
        }
        final difference = canBeSeenUntil!.difference(clock.now());
        // Calculate the progress as a value between 0.0 and 1.0
        progress.value =
            difference.inMilliseconds / (mediaFile.displayLimitInMilliseconds!);
      });
    }
  }

  Future<void> onPressedSaveToGallery() async {
    setState(() {
      imageSaving = true;
    });
    await currentMedia!.storeMediaFile();
    await twonlyDB.messagesDao.updateMessageId(
      currentMessage!.messageId,
      const MessagesCompanion(
        mediaStored: Value(true),
      ),
    );
    await sendCipherTextToGroup(
      widget.group.groupId,
      pb.EncryptedContent(
        mediaUpdate: pb.EncryptedContent_MediaUpdate(
          type: pb.EncryptedContent_MediaUpdate_Type.STORED,
          targetMessageId: currentMessage!.messageId,
        ),
      ),
    );
    setState(() {
      imageSaved = true;
      imageSaving = false;
    });
  }

  void displayShortReactions() {
    final renderBox =
        mediaWidgetKey.currentContext!.findRenderObject() as RenderBox?;
    setState(() {
      showShortReactions = true;
      if (renderBox != null) {
        mediaViewerDistanceFromBottom = renderBox.size.height;
      }
    });
  }

  Widget bottomNavigation() {
    return Row(
      key: mediaWidgetKey,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (currentMedia != null &&
            !currentMedia!.mediaFile.requiresAuthentication &&
            currentMedia!.mediaFile.displayLimitInMilliseconds == null)
          MyIconButton(
            variant: MyIconButtonVariant.secondary,
            onPressed: (currentMedia == null) ? null : onPressedSaveToGallery,
            icon: imageSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
                : imageSaved
                ? const Icon(Icons.check)
                : const FaIcon(FontAwesomeIcons.floppyDisk, size: 20),
          ),
        const SizedBox(width: 10),
        IconButton(
          icon: SizedBox(
            width: 30,
            height: 30,
            child: GridView.count(
              crossAxisCount: 2,
              children: List.generate(
                4,
                (index) {
                  return SizedBox(
                    width: 8,
                    height: 8,
                    child: Center(
                      child: EmojiAnimationComp(
                        emoji: EmojiAnimationComp.animatedIcons.keys
                            .toList()[index],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          onPressed: () {
            if (!showShortReactions) {
              displayShortReactions();
            } else {
              setState(() {
                showShortReactions = false;
              });
            }
          },
          style: ButtonStyle(
            padding: WidgetStateProperty.all<EdgeInsets>(
              const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
          ),
        ),
        const SizedBox(width: 10),
        MyIconButton(
          variant: MyIconButtonVariant.secondary,
          onPressed: () async {
            displayShortReactions();
            setState(() {
              showSendTextMessageInput = true;
            });
          },
          icon: const FaIcon(
            FontAwesomeIcons.message,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        MyIconButton(
          onPressed: () async {
            nextMediaTimer?.cancel();
            progressTimer?.cancel();
            await videoController?.pause();
            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return CameraSendToView(widget.group);
                },
              ),
            );
            if (mounted &&
                currentMedia!.mediaFile.displayLimitInMilliseconds != null) {
              await advanceToNextMediaOrExit();
            } else {
              await videoController?.play();
            }
          },
          icon: const FaIcon(FontAwesomeIcons.camera, size: 24),
        ),
      ],
    );
  }

  Widget _loader() {
    return Center(
      child: SizedBox(
        height: 60,
        width: 60,
        child: ThreeRotatingDots(
          size: 40,
          color: context.color.primary,
        ),
      ),
    );
  }

  void _sendTextMessage() {
    if (textMessageController.text.isNotEmpty) {
      unawaited(
        insertAndSendTextMessage(
          widget.group.groupId,
          textMessageController.text,
          currentMessage!.messageId,
        ),
      );
      textMessageController.clear();
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      showSendTextMessageInput = false;
      showShortReactions = false;
      _lastTimeInputClosed = clock.now();
    });
  }

  void onScreenTapped() {
    if (_lastTimeInputClosed != null &&
        clock.now().difference(_lastTimeInputClosed!) <
            const Duration(milliseconds: 300)) {
      return;
    }
    if (showSendTextMessageInput) {
      setState(() {
        showShortReactions = false;
        showSendTextMessageInput = false;
        _lastTimeInputClosed = clock.now();
      });
      return;
    }
    advanceToNextMediaOrExit();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    if (bottomInset > maxBottomInset) {
      maxBottomInset = bottomInset;
    } else if (bottomInset == 0 && maxBottomInset > 0) {
      maxBottomInset = 0;
      if (showSendTextMessageInput) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              showSendTextMessageInput = false;
              showShortReactions = false;
              _lastTimeInputClosed = clock.now();
            });
          }
        });
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_showDownloadingLoader) _loader(),
            if ((currentMedia != null || videoController != null) &&
                (canBeSeenUntil == null || progress.value >= 0))
              GestureDetector(
                onTap: onScreenTapped,
                onDoubleTap: (videoController == null) ? null : onScreenTapped,
                child: MediaViewSizingHelper(
                  bottomNavigation: bottomNavigation(),
                  requiredHeight: 55,
                  child: MediaContentRenderer(
                    currentMedia: currentMedia,
                    videoController: videoController,
                    loader: _loader(),
                  ),
                ),
              ),
            if (displayTwonlyPresent)
              TwonlyPresentOverlay(
                onTap: () => loadAndDownloadCurrentMedia(showTwonly: true),
              ),
            if (currentMedia != null &&
                currentMedia?.mediaFile.downloadState != DownloadState.ready)
              Positioned.fill(child: _loader()),
            if (canBeSeenUntil != null || progress.value >= 0)
              Positioned(
                right: 20,
                top: 27,
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: ValueListenableBuilder<double>(
                        valueListenable: progress,
                        builder: (context, value, child) {
                          return CircularProgressIndicator(
                            value: value,
                            strokeWidth: 2,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              top: 10,
              left: showSendTextMessageInput ? 0 : null,
              right: showSendTextMessageInput ? 0 : 15,
              child: Text(
                _currentMediaSender,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: showSendTextMessageInput ? 24 : 14,
                  fontWeight: FontWeight.bold,
                  color: showSendTextMessageInput
                      ? null
                      : const Color.fromARGB(255, 126, 126, 126),
                  shadows: const [
                    Shadow(
                      color: Color.fromARGB(122, 0, 0, 0),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            if (showSendTextMessageInput)
              MediaViewerMessageInput(
                controller: textMessageController,
                onSubmitted: (value) => _sendTextMessage(),
                onSendPressed: _sendTextMessage,
              ),
            if (currentMessage != null)
              AdditionalMessageContent(currentMessage!),
            if (currentMedia != null)
              ReactionButtons(
                show: showShortReactions,
                textInputFocused: showSendTextMessageInput,
                mediaViewerDistanceFromBottom: mediaViewerDistanceFromBottom,
                groupId: widget.group.groupId,
                messageId: currentMessage!.messageId,
                emojiKey: emojiKey,
                hide: () {
                  setState(() {
                    showShortReactions = false;
                    showSendTextMessageInput = false;
                    _lastTimeInputClosed = clock.now();
                  });
                },
              ),
            Positioned.fill(
              child: EmojiFloatWidget(key: emojiKey),
            ),
          ],
        ),
      ),
    );
  }
}
