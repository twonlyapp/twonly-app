import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart'
    show DownloadState, MediaType;
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/services/api/mediafiles/download.service.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/background.notifications.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/camera_send_to_view.dart';
import 'package:twonly/src/views/chats/media_viewer_components/reaction_buttons.component.dart';
import 'package:twonly/src/views/components/animate_icon.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';
import 'package:video_player/video_player.dart';

final NoScreenshot _noScreenshot = NoScreenshot.instance;

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

  MediaFileService? currentMedia;
  Message? currentMessage;

  DateTime? canBeSeenUntil;
  double progress = 0;
  bool showSendTextMessageInput = false;
  final GlobalKey mediaWidgetKey = GlobalKey();

  bool imageSaved = false;
  bool imageSaving = false;
  bool displayTwonlyPresent = true;

  StreamSubscription<MediaFile?>? downloadStateListener;

  List<Message> allMediaFiles = [];
  late StreamSubscription<List<Message>> _subscription;
  TextEditingController textMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initialMessage != null) {
      allMediaFiles = [widget.initialMessage!];
    }

    asyncLoadNextMedia(true);
  }

  @override
  void dispose() {
    nextMediaTimer?.cancel();
    progressTimer?.cancel();
    _noScreenshot.screenshotOn();
    _subscription.cancel();
    downloadStateListener?.cancel();
    videoController?.dispose();
    super.dispose();
  }

  Future<void> asyncLoadNextMedia(bool firstRun) async {
    final messages =
        twonlyDB.messagesDao.watchMediaNotOpened(widget.group.groupId);

    _subscription = messages.listen((messages) async {
      for (final msg in messages) {
        if (msg.mediaId == currentMedia?.mediaFile.mediaId) {
          // The update of the current Media in case of a download is done in loadCurrentMediaFile
          continue;
        }

        /// If the messages was already there just replace it and go to the next...

        final index =
            allMediaFiles.indexWhere((m) => m.messageId == msg.messageId);

        if (index >= 1) {
          allMediaFiles[index] = msg;
        } else if (index == -1) {
          // If the message does not exist, add it
          allMediaFiles.add(msg);
        }
      }
      setState(() {});
      if (firstRun) {
        // ignore: parameter_assignments
        firstRun = false;
        await loadCurrentMediaFile();
      }
    });
  }

  Future<void> nextMediaOrExit() async {
    /// Remove the current media file in case it is not set to unlimited
    if (currentMedia != null) {
      if (!imageSaved &&
          currentMedia!.mediaFile.displayLimitInMilliseconds != null) {
        currentMedia!.fullMediaRemoval();
      }
    }

    await videoController?.dispose();
    if (!mounted) return;

    nextMediaTimer?.cancel();
    progressTimer?.cancel();

    if (allMediaFiles.isEmpty) {
      Navigator.pop(context);
    } else {
      await loadCurrentMediaFile();
    }
  }

  Future<void> loadCurrentMediaFile({bool showTwonly = false}) async {
    if (!mounted || !context.mounted) return;
    if (allMediaFiles.isEmpty) return nextMediaOrExit();
    await _noScreenshot.screenshotOff();

    setState(() {
      videoController = null;
      currentMedia = null;
      currentMessage = null;
      canBeSeenUntil = null;
      imageSaving = false;
      imageSaved = false;
      progress = 0;
      showSendTextMessageInput = false;
    });

    // if (Platform.isAndroid) {
    //   await flutterLocalNotificationsPlugin
    //       .cancel(allMediaFiles.first.contactId);
    // } else {
    await flutterLocalNotificationsPlugin.cancelAll();
    // }

    final stream =
        twonlyDB.mediaFilesDao.watchMedia(currentMedia!.mediaFile.mediaId);

    var downloadTriggered = false;

    await downloadStateListener?.cancel();
    downloadStateListener = stream.listen((updated) async {
      if (updated == null) return;
      if (updated.downloadState != DownloadState.downloaded) {
        if (!downloadTriggered) {
          downloadTriggered = true;
          await startDownloadMedia(currentMedia!.mediaFile, true);
          unawaited(tryDownloadAllMediaFiles(force: true));
        }
        return;
      }

      await downloadStateListener?.cancel();
      await handleNextDownloadedMedia(showTwonly);
      // start downloading all the other possible missing media files.
    });
  }

  Future<void> handleNextDownloadedMedia(
    bool showTwonly,
  ) async {
    currentMessage = allMediaFiles.removeAt(0);
    final currentMediaLocal =
        await MediaFileService.fromMediaId(currentMessage!.mediaId!);
    if (currentMediaLocal == null || !mounted) return;

    if (currentMediaLocal.mediaFile.requiresAuthentication) {
      if (!showTwonly) return;

      final isAuth = await authenticateUser(
        context.lang.mediaViewerAuthReason,
        force: false,
      );
      if (!isAuth) {
        await nextMediaOrExit();
        return;
      }
    }

    await notifyContactAboutOpeningMessage(
      currentMessage!.senderId!,
      [currentMessage!.messageId],
    );

    await twonlyDB.messagesDao.updateMessageId(
      currentMessage!.messageId,
      MessagesCompanion(openedAt: Value(DateTime.now())),
    );

    if (!currentMediaLocal.tempPath.existsSync()) {
      Log.error('Temp media file not found...');
      await handleMediaError(currentMediaLocal.mediaFile);
      return nextMediaOrExit();
    }

    if (currentMediaLocal.mediaFile.type == MediaType.video) {
      videoController = VideoPlayerController.file(currentMediaLocal.tempPath);
      await videoController?.setLooping(
        currentMediaLocal.mediaFile.displayLimitInMilliseconds == null,
      );
      await videoController?.initialize().then((_) {
        videoController!.play();
        videoController?.addListener(() {
          setState(() {
            progress = 1 -
                videoController!.value.position.inSeconds /
                    videoController!.value.duration.inSeconds;
          });
          if (currentMediaLocal.mediaFile.displayLimitInMilliseconds != null) {
            if (videoController?.value.position ==
                videoController?.value.duration) {
              nextMediaOrExit();
            }
          }
        });
        // ignore: invalid_return_type_for_catch_error, argument_type_not_assignable_to_error_handler
      }).catchError(Log.error);
    } else {
      if (currentMediaLocal.mediaFile.displayLimitInMilliseconds != null) {
        canBeSeenUntil = DateTime.now().add(
          Duration(
            milliseconds:
                currentMediaLocal.mediaFile.displayLimitInMilliseconds!,
          ),
        );
        startTimer();
      }
    }
    setState(() {
      currentMedia = currentMediaLocal;
    });
  }

  void startTimer() {
    nextMediaTimer?.cancel();
    progressTimer?.cancel();
    nextMediaTimer = Timer(canBeSeenUntil!.difference(DateTime.now()), () {
      if (context.mounted) {
        nextMediaOrExit();
      }
    });
    progressTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (canBeSeenUntil != null) {
        final difference = canBeSeenUntil!.difference(DateTime.now());
        // Calculate the progress as a value between 0.0 and 1.0
        progress = difference.inMilliseconds /
            (currentMedia!.mediaFile.displayLimitInMilliseconds!);
        setState(() {});
      }
    });
  }

  Future<void> onPressedSaveToGallery() async {
    setState(() {
      imageSaving = true;
    });
    await currentMedia!.storeMediaFile();
    await sendCipherTextToGroup(
      widget.group.groupId,
      pb.EncryptedContent(
        mediaUpdate: pb.EncryptedContent_MediaUpdate(
          type: pb.EncryptedContent_MediaUpdate_Type.STORED,
          targetMediaId: currentMedia!.mediaFile.mediaId,
        ),
      ),
    );
    setState(() {
      imageSaved = true;
    });

    if (gUser.storeMediaFilesInGallery) {
      if (currentMedia!.mediaFile.type == MediaType.video) {
        await saveVideoToGallery(currentMedia!.storedPath.path);
      } else if (currentMedia!.mediaFile.type == MediaType.image) {
        final imageBytes = await currentMedia!.storedPath.readAsBytes();
        await saveImageToGallery(imageBytes);
      }
    }
    setState(() {
      imageSaving = false;
    });
  }

  void displayShortReactions() {
    final renderBox =
        mediaWidgetKey.currentContext!.findRenderObject()! as RenderBox;
    setState(() {
      showShortReactions = true;
      mediaViewerDistanceFromBottom = renderBox.size.height;
    });
  }

  Widget bottomNavigation() {
    return Row(
      key: mediaWidgetKey,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (currentMedia != null &&
            currentMedia!.mediaFile.displayLimitInMilliseconds == null)
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              iconColor: imageSaved
                  ? Theme.of(context).colorScheme.outline
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: imageSaved
                  ? Theme.of(context).colorScheme.outline
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: (currentMedia == null) ? null : onPressedSaveToGallery,
            child: Row(
              children: [
                if (imageSaving)
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1),
                  )
                else
                  imageSaved
                      ? const Icon(Icons.check)
                      : const FaIcon(FontAwesomeIcons.floppyDisk),
              ],
            ),
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
                      child: EmojiAnimation(
                        emoji:
                            EmojiAnimation.animatedIcons.keys.toList()[index],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          onPressed: () async {
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
        IconButton.outlined(
          icon: const FaIcon(FontAwesomeIcons.message),
          onPressed: () async {
            displayShortReactions();
            setState(() {
              showSendTextMessageInput = true;
            });
          },
          style: ButtonStyle(
            padding: WidgetStateProperty.all<EdgeInsets>(
              const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.outlined(
          icon: const FaIcon(FontAwesomeIcons.camera),
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
              await nextMediaOrExit();
            } else {
              await videoController?.play();
            }
          },
          style: ButtonStyle(
            padding: WidgetStateProperty.all<EdgeInsets>(
              const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if ((currentMedia != null || videoController != null) &&
                (canBeSeenUntil == null || progress >= 0))
              GestureDetector(
                onTap: () {
                  if (showSendTextMessageInput) {
                    setState(() {
                      showShortReactions = false;
                      showSendTextMessageInput = false;
                    });
                    return;
                  }
                  nextMediaOrExit();
                },
                child: MediaViewSizing(
                  bottomNavigation: bottomNavigation(),
                  requiredHeight: 90,
                  child: Stack(
                    children: [
                      if (videoController != null)
                        Positioned.fill(
                          child: VideoPlayer(videoController!),
                        ),
                      if (currentMedia!.mediaFile.type == MediaType.image)
                        Positioned.fill(
                          child: Image.file(
                            currentMedia!.tempPath,
                            fit: BoxFit.contain,
                            frameBuilder: (
                              context,
                              child,
                              frame,
                              wasSynchronouslyLoaded,
                            ) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: frame != null
                                    ? child
                                    : Container(
                                        height: 60,
                                        color: Colors.transparent,
                                        width: 60,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (currentMedia != null &&
                currentMedia!.mediaFile.requiresAuthentication &&
                displayTwonlyPresent)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    loadCurrentMediaFile(showTwonly: true);
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Lottie.asset(
                          'assets/animations/present.lottie.json',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 200),
                        child: Text(context.lang.mediaViewerTwonlyTapToOpen),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 10,
              top: 10,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, size: 30),
                    color: Colors.white,
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            if (currentMedia?.mediaFile.downloadState !=
                DownloadState.downloaded)
              const Positioned.fill(
                child: Center(
                  child: SizedBox(
                    height: 60,
                    width: 60,
                    child: CircularProgressIndicator(strokeWidth: 6),
                  ),
                ),
              ),
            if (canBeSeenUntil != null || progress >= 0)
              Positioned(
                right: 20,
                top: 27,
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2,
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
                widget.group.groupName,
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
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: context.color.surface,
                  padding: const EdgeInsets.only(
                    bottom: 10,
                    left: 20,
                    right: 20,
                    top: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.xmark),
                        onPressed: () {
                          setState(() {
                            showShortReactions = false;
                            showSendTextMessageInput = false;
                          });
                        },
                      ),
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          controller: textMessageController,
                          onEditingComplete: () {
                            setState(() {
                              showSendTextMessageInput = false;
                              showShortReactions = false;
                            });
                          },
                          decoration: inputTextMessageDeco(context),
                        ),
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.solidPaperPlane),
                        onPressed: () async {
                          if (textMessageController.text.isNotEmpty) {
                            await insertAndSendTextMessage(
                              widget.group.groupId,
                              textMessageController.text,
                              currentMessage!.messageId,
                            );
                            textMessageController.clear();
                          }
                          setState(() {
                            showSendTextMessageInput = false;
                            showShortReactions = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            if (currentMedia != null)
              ReactionButtons(
                show: showShortReactions,
                textInputFocused: showSendTextMessageInput,
                mediaViewerDistanceFromBottom: mediaViewerDistanceFromBottom,
                groupId: widget.group.groupId,
                messageId: currentMessage!.messageId,
                hide: () {
                  setState(() {
                    showShortReactions = false;
                    showSendTextMessageInput = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}
