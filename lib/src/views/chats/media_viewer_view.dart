import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/components/animate_icon.dart';
import 'package:twonly/src/components/media_view_sizing.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/json_models/message.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api/media.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera_to_share/share_image_view.dart';
import 'package:twonly/src/views/chats/chat_item_details_view.dart';
import 'package:twonly/src/views/home_view.dart';

final _noScreenshot = NoScreenshot.instance;

class MediaViewerView extends StatefulWidget {
  final Contact contact;
  const MediaViewerView(this.contact, {super.key});

  @override
  State<MediaViewerView> createState() => _MediaViewerViewState();
}

class _MediaViewerViewState extends State<MediaViewerView> {
  Timer? nextMediaTimer;
  Timer? progressTimer;

  bool showShortReactions = false;
  int selectedShortReaction = -1;

  // current image related
  Uint8List? imageBytes;
  DateTime? canBeSeenUntil;
  int maxShowTime = 999999;
  double progress = 0;
  bool isRealTwonly = false;
  bool isDownloading = false;

  bool imageSaved = false;
  bool imageSaving = false;

  List<Message> allMediaFiles = [];
  late StreamSubscription<List<Message>> _subscription;

  @override
  void initState() {
    super.initState();

    asyncLoadNextMedia(true);
  }

  Future asyncLoadNextMedia(bool firstRun) async {
    Stream<List<Message>> messages = twonlyDatabase.messagesDao
        .watchMediaMessageNotOpened(widget.contact.userId);

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
        } else {
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
    nextMediaTimer?.cancel();
    progressTimer?.cancel();
    if (allMediaFiles.isEmpty || allMediaFiles.length == 1) {
      if (context.mounted) {
        Navigator.pop(context);
      }
    } else {
      allMediaFiles.removeAt(0);
      loadCurrentMediaFile();
    }
  }

  Future loadCurrentMediaFile({bool showTwonly = false}) async {
    await _noScreenshot.screenshotOff();
    if (!context.mounted || allMediaFiles.isEmpty) return nextMediaOrExit();

    final current = allMediaFiles.first;
    final MediaMessageContent content =
        MediaMessageContent.fromJson(jsonDecode(current.contentJson!));

    setState(() {
      imageBytes = null;
      canBeSeenUntil = null;
      maxShowTime = 999999;
      imageSaving = false;
      imageSaved = false;
      progress = 0;
      isDownloading = false;
      isRealTwonly = false;
    });

    if (content.isRealTwonly) {
      setState(() {
        isRealTwonly = true;
      });
      if (!showTwonly) {
        return;
      }

      if (isRealTwonly) {
        if (!context.mounted) return;
        bool isAuth = await authenticateUser(context.lang.mediaViewerAuthReason,
            force: false);
        if (!isAuth) {
          nextMediaOrExit();
          return;
        }
      }
    }
    flutterLocalNotificationsPlugin.cancel(current.contactId);
    if (current.downloadState == DownloadState.pending) {
      setState(() {
        isDownloading = true;
      });
      await tryDownloadMedia(current.messageId, current.contactId, content,
          force: true);
    }
    do {
      if (isDownloading) {
        await Future.delayed(Duration(milliseconds: 10));
        if (!apiProvider.isConnected) break;
      }
      if (content.downloadToken == null) break;
      imageBytes = await getDownloadedMedia(current, content.downloadToken!);
    } while (isDownloading && imageBytes == null);

    isDownloading = false;
    if (imageBytes == null) {
      if (current.downloadState == DownloadState.downloaded) {
        // When the message should be downloaded but imageBytes are null then a error happened
        await twonlyDatabase.messagesDao.updateMessageByMessageId(
          current.messageId,
          MessagesCompanion(
            errorWhileSending: Value(true),
          ),
        );
      }

      nextMediaOrExit();
      return;
    }

    if (content.maxShowTime != 999999) {
      canBeSeenUntil = DateTime.now().add(
        Duration(seconds: content.maxShowTime),
      );
      maxShowTime = content.maxShowTime;
      startTimer();
    }
    setState(() {});
  }

  startTimer() {
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

  @override
  void dispose() {
    super.dispose();
    nextMediaTimer?.cancel();
    progressTimer?.cancel();
    _noScreenshot.screenshotOn();
    _subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageBytes != null && (canBeSeenUntil == null || progress >= 0))
              GestureDetector(
                onTap: () {
                  nextMediaOrExit();
                },
                child: MediaViewSizing(
                  Image.memory(
                    imageBytes!,
                    fit: BoxFit.contain,
                    frameBuilder:
                        ((context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: frame != null
                            ? child
                            : SizedBox(
                                height: 60,
                                width: 60,
                                child:
                                    CircularProgressIndicator(strokeWidth: 6),
                              ),
                      );
                    }),
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
                        child: Text("Tap to open your twonly!"),
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
            Positioned(
              right: 20,
              top: 27,
              child: Row(
                children: [
                  if (canBeSeenUntil != null)
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
            AnimatedPositioned(
              duration: Duration(milliseconds: 200), // Animation duration
              bottom: showShortReactions ? 100 : 90,
              left: showShortReactions ? 0 : 150,
              right: showShortReactions ? 0 : 150,
              curve: Curves.linearToEaseOut,
              child: AnimatedOpacity(
                opacity: showShortReactions ? 1.0 : 0.0, // Fade in/out
                duration: Duration(milliseconds: 150),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    6,
                    (index) {
                      final emoji =
                          EmojiAnimation.animatedIcons.keys.toList()[index];
                      return AnimatedSize(
                        duration:
                            Duration(milliseconds: 200), // Animation duration
                        curve: Curves.linearToEaseOut,
                        child: GestureDetector(
                          onTap: () {
                            sendTextMessage(
                              widget.contact.userId,
                              TextMessageContent(
                                text: emoji,
                                responseToMessageId:
                                    allMediaFiles.first.messageOtherId,
                              ),
                              PushKind.reaction,
                            );
                            setState(() {
                              selectedShortReaction = index;
                            });
                            Future.delayed(Duration(milliseconds: 300), () {
                              setState(() {
                                showShortReactions = false;
                              });
                            });
                          },
                          child: (selectedShortReaction == index)
                              ? EmojiAnimationFlying(
                                  emoji: emoji,
                                  duration: Duration(milliseconds: 300),
                                  startPosition: 0.0,
                                  size: (showShortReactions) ? 40 : 10)
                              : AnimatedOpacity(
                                  opacity: (selectedShortReaction == -1)
                                      ? 1
                                      : 0, // Fade in/out
                                  duration: Duration(milliseconds: 150),
                                  child: SizedBox(
                                    width: showShortReactions ? 40 : 10,
                                    child: Center(
                                      child: EmojiAnimation(
                                        emoji: emoji,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (imageBytes != null)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (maxShowTime == 999999)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          iconColor: imageSaved
                              ? Theme.of(context).colorScheme.outline
                              : Theme.of(context).colorScheme.primary,
                          foregroundColor: imageSaved
                              ? Theme.of(context).colorScheme.outline
                              : Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () async {
                          if (allMediaFiles.first.messageOtherId == null) {
                            return; // should not be possible
                          }
                          setState(() {
                            imageSaving = true;
                          });
                          encryptAndSendMessage(
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
                            pushKind: PushKind.storedMediaFile,
                          );
                          final res = await saveImageToGallery(imageBytes!);
                          if (res == null) {
                            setState(() {
                              imageSaving = false;
                              imageSaved = true;
                            });
                          }
                        },
                        child: Row(
                          children: [
                            imageSaving
                                ? SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1))
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
                                    emoji: EmojiAnimation.animatedIcons.keys
                                        .toList()[index],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      onPressed: () async {
                        setState(() {
                          showShortReactions = !showShortReactions;
                          selectedShortReaction = -1;
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
                      icon: FaIcon(FontAwesomeIcons.message),
                      onPressed: () async {
                        Navigator.popUntil(context, (route) => route.isFirst);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) {
                            return ChatItemDetailsView(widget.contact);
                          }),
                        );
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
                        globalSendNextMediaToUser = widget.contact;
                        globalUpdateOfHomeViewPageIndex(0);
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all<EdgeInsets>(
                          EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
