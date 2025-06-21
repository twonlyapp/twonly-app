import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/model/protobuf/push_notification/push_notification.pb.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/services/notifications/background.notifications.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/views/camera/share_image_editor_view.dart';
import 'package:twonly/src/views/components/animate_icon.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/api/media_download.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera/camera_send_to_view.dart';
import 'package:video_player/video_player.dart';

final _noScreenshot = NoScreenshot.instance;

class MediaViewerView extends StatefulWidget {
  final Contact contact;
  const MediaViewerView(this.contact, {super.key, this.initialMessage});

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
  Uint8List? imageBytes;
  String? videoPath;
  VideoPlayerController? videoController;

  DateTime? canBeSeenUntil;
  int maxShowTime = 999999;
  double progress = 0;
  bool isRealTwonly = false;
  bool mirrorVideo = false;
  bool isDownloading = false;
  bool showSendTextMessageInput = false;
  final GlobalKey mediaWidgetKey = GlobalKey();

  bool imageSaved = false;
  bool imageSaving = false;

  StreamSubscription<Message?>? downloadStateListener;

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

  Future asyncLoadNextMedia(bool firstRun) async {
    Stream<List<Message>> messages =
        twonlyDB.messagesDao.watchMediaMessageNotOpened(widget.contact.userId);

    _subscription = messages.listen((messages) {
      for (Message msg in messages) {
        // if (!allMediaFiles.any((m) => m.messageId == msg.messageId)) {
        //   allMediaFiles.add(msg);
        // }
        // Find the index of the existing message with the same messageId
        int index =
            allMediaFiles.indexWhere((m) => m.messageId == msg.messageId);

        if (index >= 1) {
          // to not modify the first message
          // If the message exists, replace it
          allMediaFiles[index] = msg;
        } else if (index == -1) {
          // If the message does not exist, add it
          allMediaFiles.add(msg);
        }
      }
      setState(() {});
      if (firstRun) {
        loadCurrentMediaFile();
        firstRun = false;
      }
    });
  }

  Future nextMediaOrExit() async {
    if (!mounted) return;
    videoController?.dispose();
    nextMediaTimer?.cancel();
    progressTimer?.cancel();
    if (allMediaFiles.isNotEmpty) {
      try {
        if (!imageSaved && maxShowTime != gMediaShowInfinite) {
          await deleteMediaFile(allMediaFiles.first.messageId, "mp4");
          await deleteMediaFile(allMediaFiles.first.messageId, "png");
        }
      } catch (e) {
        Log.error("$e");
      }
    }
    if (allMediaFiles.isEmpty || allMediaFiles.length == 1) {
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      allMediaFiles.removeAt(0);
      await loadCurrentMediaFile();
    }
  }

  Future loadCurrentMediaFile({bool showTwonly = false}) async {
    if (!mounted) return;
    if (!context.mounted || allMediaFiles.isEmpty) return nextMediaOrExit();
    await _noScreenshot.screenshotOff();

    setState(() {
      videoController = null;
      imageBytes = null;
      canBeSeenUntil = null;
      maxShowTime = 999999;
      imageSaving = false;
      imageSaved = false;
      mirrorVideo = false;
      progress = 0;
      videoPath = null;
      isDownloading = false;
      isRealTwonly = false;
      showSendTextMessageInput = false;
    });

    flutterLocalNotificationsPlugin.cancel(allMediaFiles.first.contactId);

    if (allMediaFiles.first.downloadState != DownloadState.downloaded) {
      setState(() {
        isDownloading = true;
      });
      await startDownloadMedia(allMediaFiles.first, true);

      final stream = twonlyDB.messagesDao
          .getMessageByMessageId(allMediaFiles.first.messageId)
          .watchSingleOrNull();
      downloadStateListener?.cancel();
      downloadStateListener = stream.listen((updated) async {
        if (updated != null) {
          if (updated.downloadState == DownloadState.downloaded) {
            downloadStateListener?.cancel();
            await handleNextDownloadedMedia(updated, showTwonly);
            // start downloading all the other possible missing media files.
            tryDownloadAllMediaFiles(force: true);
          }
        }
      });
    } else {
      await handleNextDownloadedMedia(allMediaFiles.first, showTwonly);
    }
  }

  Future handleNextDownloadedMedia(Message current, bool showTwonly) async {
    final MediaMessageContent content =
        MediaMessageContent.fromJson(jsonDecode(current.contentJson!));

    if (content.isRealTwonly) {
      setState(() {
        isRealTwonly = true;
      });
      if (!showTwonly) return;

      bool isAuth = await authenticateUser(
        context.lang.mediaViewerAuthReason,
        force: false,
      );
      if (!isAuth) {
        nextMediaOrExit();
        return;
      }
    }

    await notifyContactAboutOpeningMessage(
      current.contactId,
      [current.messageOtherId!],
    );

    await twonlyDB.messagesDao.updateMessageByMessageId(
      current.messageId,
      MessagesCompanion(openedAt: Value(DateTime.now())),
    );

    if (content.isVideo) {
      final videoPathTmp = await getVideoPath(current.messageId);
      if (videoPathTmp != null) {
        videoController = VideoPlayerController.file(File(videoPathTmp.path));
        videoController?.setLooping(content.maxShowTime == gMediaShowInfinite);
        videoController?.initialize().then((_) {
          videoController!.play();
          videoController?.addListener(() {
            setState(() {
              progress = 1 -
                  videoController!.value.position.inSeconds /
                      videoController!.value.duration.inSeconds;
            });
            if (content.maxShowTime != gMediaShowInfinite) {
              if (videoController?.value.position ==
                  videoController?.value.duration) {
                nextMediaOrExit();
              }
            }
          });
          setState(() {
            videoPath = videoPathTmp.path;
          });
        }).catchError((Object error) {
          Log.error(error);
        });
      }
    }

    imageBytes = await getImageBytes(current.messageId);

    if ((imageBytes == null && !content.isVideo) ||
        (content.isVideo && videoController == null)) {
      Log.error("media files are not found...");
      // When the message should be downloaded but imageBytes are null then a error happened
      await handleMediaError(current);
      return nextMediaOrExit();
    }

    if (!content.isVideo) {
      if (content.maxShowTime != gMediaShowInfinite) {
        canBeSeenUntil = DateTime.now().add(
          Duration(seconds: content.maxShowTime),
        );
        startTimer();
      }
    }
    setState(() {
      maxShowTime = content.maxShowTime;
      isDownloading = false;
      mirrorVideo = content.mirrorVideo;
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
    progressTimer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      if (canBeSeenUntil != null) {
        Duration difference = canBeSeenUntil!.difference(DateTime.now());
        // Calculate the progress as a value between 0.0 and 1.0
        progress = (difference.inMilliseconds / (maxShowTime * 1000));
        setState(() {});
      }
    });
  }

  Future onPressedSaveToGallery() async {
    if (allMediaFiles.first.messageOtherId == null) {
      return; // should not be possible
    }
    setState(() {
      imageSaving = true;
    });
    await twonlyDB.messagesDao.updateMessageByMessageId(
      allMediaFiles.first.messageId,
      MessagesCompanion(mediaStored: Value(true)),
    );
    await encryptAndSendMessageAsync(
      null,
      widget.contact.userId,
      MessageJson(
        kind: MessageKind.storedMediaFile,
        messageId: allMediaFiles.first.messageId,
        content: StoredMediaFileContent(
          messageId: allMediaFiles.first.messageOtherId!,
        ),
        timestamp: DateTime.now(),
      ),
      pushNotification: PushNotification(kind: PushKind.acceptRequest),
    );
    setState(() {
      imageSaved = true;
    });
    final user = await getUser();
    if (user != null && (user.storeMediaFilesInGallery)) {
      if (videoPath != null) {
        await saveVideoToGallery(videoPath!);
      } else {
        await saveImageToGallery(imageBytes!);
      }
    }
    setState(() {
      imageSaving = false;
    });
  }

  void displayShortReactions() {
    RenderBox renderBox =
        mediaWidgetKey.currentContext?.findRenderObject() as RenderBox;
    setState(() {
      showShortReactions = true;
      mediaViewerDistanceFromBottom = renderBox.size.height;
    });
  }

  Widget bottomNavigation() {
    return Row(
      key: mediaWidgetKey,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (maxShowTime == gMediaShowInfinite)
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              iconColor: imageSaved
                  ? Theme.of(context).colorScheme.outline
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: imageSaved
                  ? Theme.of(context).colorScheme.outline
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: onPressedSaveToGallery,
            child: Row(
              children: [
                imageSaving
                    ? SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1))
                    : imageSaved
                        ? Icon(Icons.check)
                        : FaIcon(FontAwesomeIcons.floppyDisk),
              ],
            ),
          ),
        SizedBox(width: 10),
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
              EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
          ),
        ),
        SizedBox(width: 10),
        IconButton.outlined(
          icon: FaIcon(FontAwesomeIcons.message),
          onPressed: () async {
            displayShortReactions();
            setState(() {
              showSendTextMessageInput = true;
            });
          },
          style: ButtonStyle(
            padding: WidgetStateProperty.all<EdgeInsets>(
              EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
          ),
        ),
        SizedBox(width: 10),
        IconButton.outlined(
          icon: FaIcon(FontAwesomeIcons.camera),
          onPressed: () async {
            nextMediaTimer?.cancel();
            progressTimer?.cancel();
            videoController?.pause();
            await Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return CameraSendToView(widget.contact);
              },
            ));
            if (mounted && maxShowTime != gMediaShowInfinite) {
              nextMediaOrExit();
            } else {
              videoController?.play();
            }
          },
          style: ButtonStyle(
            padding: WidgetStateProperty.all<EdgeInsets>(
              EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
            if ((imageBytes != null || videoController != null) &&
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
                          child: Transform.flip(
                            flipX: mirrorVideo,
                            child: VideoPlayer(videoController!),
                          ),
                        ),
                      if (imageBytes != null)
                        Positioned.fill(
                          child: Image.memory(
                            imageBytes!,
                            fit: BoxFit.contain,
                            frameBuilder: ((context, child, frame,
                                wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: frame != null
                                    ? child
                                    : Container(
                                        height: 60,
                                        color: Colors.transparent,
                                        width: 60,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (isRealTwonly && imageBytes == null)
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
                        padding: EdgeInsets.only(bottom: 200),
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
                    icon: Icon(Icons.close, size: 30),
                    color: Colors.white,
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            if (isDownloading)
              Positioned.fill(
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
                        strokeWidth: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            if (showSendTextMessageInput)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Text(
                  getContactDisplayName(widget.contact),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: const Color.fromARGB(122, 0, 0, 0),
                        blurRadius: 5.0,
                      )
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
                      bottom: 10, left: 20, right: 20, top: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: FaIcon(FontAwesomeIcons.xmark),
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
                        icon: FaIcon(FontAwesomeIcons.solidPaperPlane),
                        onPressed: () {
                          if (textMessageController.text.isNotEmpty) {
                            sendTextMessage(
                              widget.contact.userId,
                              TextMessageContent(
                                text: textMessageController.text,
                                responseToMessageId:
                                    allMediaFiles.first.messageOtherId,
                              ),
                              PushNotification(
                                kind: PushKind.response,
                              ),
                            );
                            textMessageController.clear();
                          }
                          setState(() {
                            showSendTextMessageInput = false;
                            showShortReactions = false;
                          });
                        },
                      )
                    ],
                  ),
                ),
              ),
            if (allMediaFiles.isNotEmpty)
              ReactionButtons(
                show: showShortReactions,
                textInputFocused: showSendTextMessageInput,
                mediaViewerDistanceFromBottom: mediaViewerDistanceFromBottom,
                userId: widget.contact.userId,
                responseToMessageId: allMediaFiles.first.messageOtherId!,
                isVideo: videoController != null,
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

class ReactionButtons extends StatefulWidget {
  const ReactionButtons({
    super.key,
    required this.show,
    required this.textInputFocused,
    required this.userId,
    required this.mediaViewerDistanceFromBottom,
    required this.responseToMessageId,
    required this.isVideo,
    required this.hide,
  });

  final double mediaViewerDistanceFromBottom;
  final bool show;
  final bool isVideo;
  final bool textInputFocused;
  final int userId;
  final int responseToMessageId;
  final Function() hide;

  @override
  State<ReactionButtons> createState() => _ReactionButtonsState();
}

class _ReactionButtonsState extends State<ReactionButtons> {
  int selectedShortReaction = -1;

  List<String> selectedEmojis =
      EmojiAnimation.animatedIcons.keys.toList().sublist(0, 6);

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future initAsync() async {
    var user = await getUser();
    if (user != null && user.preSelectedEmojies != null) {
      selectedEmojis = user.preSelectedEmojies!;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final firstRowEmojis = selectedEmojis.take(6).toList();
    final secondRowEmojis =
        selectedEmojis.length > 6 ? selectedEmojis.skip(6).toList() : [];

    return AnimatedPositioned(
      duration: Duration(milliseconds: 200), // Animation duration
      bottom: widget.show
          ? (widget.textInputFocused
              ? 50
              : widget.mediaViewerDistanceFromBottom)
          : widget.mediaViewerDistanceFromBottom - 20,
      left: widget.show ? 0 : MediaQuery.sizeOf(context).width / 2,
      right: widget.show ? 0 : MediaQuery.sizeOf(context).width / 2,
      curve: Curves.linearToEaseOut,
      child: AnimatedOpacity(
        opacity: widget.show ? 1.0 : 0.0, // Fade in/out
        duration: Duration(milliseconds: 150),
        child: Container(
          color: widget.show ? Colors.black.withAlpha(0) : Colors.transparent,
          padding: widget.show ? EdgeInsets.symmetric(vertical: 32) : null,
          child: Column(
            children: [
              if (secondRowEmojis.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: secondRowEmojis
                      .map((emoji) => EmojiReactionWidget(
                            userId: widget.userId,
                            responseToMessageId: widget.responseToMessageId,
                            hide: widget.hide,
                            show: widget.show,
                            isVideo: widget.isVideo,
                            emoji: emoji,
                          ))
                      .toList(),
                ),
              if (secondRowEmojis.isNotEmpty) SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: firstRowEmojis
                    .map(
                      (emoji) => EmojiReactionWidget(
                        userId: widget.userId,
                        responseToMessageId: widget.responseToMessageId,
                        hide: widget.hide,
                        show: widget.show,
                        isVideo: widget.isVideo,
                        emoji: emoji,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmojiReactionWidget extends StatefulWidget {
  final int userId;
  final int responseToMessageId;
  final Function hide;
  final bool show;
  final bool isVideo;
  final String emoji;

  const EmojiReactionWidget({
    super.key,
    required this.userId,
    required this.responseToMessageId,
    required this.hide,
    required this.isVideo,
    required this.show,
    required this.emoji,
  });

  @override
  State<EmojiReactionWidget> createState() => _EmojiReactionWidgetState();
}

class _EmojiReactionWidgetState extends State<EmojiReactionWidget> {
  int selectedShortReaction = -1;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Duration(milliseconds: 200),
      curve: Curves.linearToEaseOut,
      child: GestureDetector(
        onTap: () {
          sendTextMessage(
            widget.userId,
            TextMessageContent(
              text: widget.emoji,
              responseToMessageId: widget.responseToMessageId,
            ),
            PushNotification(
              kind: widget.isVideo
                  ? PushKind.reactionToVideo
                  : PushKind.reactionToImage,
              reactionContent: widget.emoji,
            ),
          );
          setState(() {
            selectedShortReaction = 0; // Assuming index is 0 for this example
          });
          Future.delayed(Duration(milliseconds: 300), () {
            setState(() {
              widget.hide();
              selectedShortReaction = -1;
            });
          });
        },
        child: (selectedShortReaction ==
                0) // Assuming index is 0 for this example
            ? EmojiAnimationFlying(
                emoji: widget.emoji,
                duration: Duration(milliseconds: 300),
                startPosition: 0.0,
                size: (widget.show) ? 40 : 10,
              )
            : AnimatedOpacity(
                opacity: (selectedShortReaction == -1) ? 1 : 0, // Fade in/out
                duration: Duration(milliseconds: 150),
                child: SizedBox(
                  width: widget.show ? 40 : 10,
                  child: Center(
                    child: EmojiAnimation(
                      emoji: widget.emoji,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
