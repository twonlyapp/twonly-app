import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/components/animate_icon.dart';
import 'package:twonly/src/components/media_view_sizing.dart';
import 'package:twonly/src/database/database.dart';
import 'package:twonly/src/database/messages_db.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/send_next_media_to.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_item_details_view.dart';
import 'package:twonly/src/views/home_view.dart';

final _noScreenshot = NoScreenshot.instance;

class MediaViewerView extends StatefulWidget {
  final int userId;
  const MediaViewerView(this.userId, {super.key});

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

  List<Message> allMediaFiles = [];
  late StreamSubscription<List<Message>> _subscription;

  @override
  void initState() {
    super.initState();

    asyncLoadNextMedia();
    loadCurrentMediaFile();
  }

  Future asyncLoadNextMedia() async {
    Stream<List<Message>> messages =
        context.db.watchMessageNotOpened(widget.userId);

    _subscription = messages.listen((messages) {
      for (Message msg in messages) {
        if (!allMediaFiles.any((m) => m.messageId == msg.messageId)) {
          allMediaFiles.add(msg);
        }
      }
      setState(() {});
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
    if (!context.mounted || allMediaFiles.isEmpty) return;

    final Message current = allMediaFiles.first;
    final MessageJson messageJson =
        MessageJson.fromJson(jsonDecode(current.contentJson!));
    final MessageContent? content = messageJson.content;

    setState(() {
      // reset current image values
      imageBytes = null;
      canBeSeenUntil = null;
      maxShowTime = 999999;
      progress = 0;
      isDownloading = false;
      isRealTwonly = false;
    });

    if (content is MediaMessageContent) {
      if (content.isRealTwonly) {
        setState(() {
          isRealTwonly = true;
        });
        if (!showTwonly) {
          return;
        }
      }

      if (isRealTwonly) {
        bool isAuth = await authenticateUser(context.lang.mediaViewerAuthReason,
            force: false);
        if (!isAuth) {
          nextMediaOrExit();
          return;
        }
      }
      flutterLocalNotificationsPlugin.cancel(current.messageId);
      if (current.downloadState == DownloadState.pending) {
        setState(() {
          isDownloading = true;
        });
        await tryDownloadMedia(
            current.messageId, current.contactId, content.downloadToken,
            force: true);
      }
      do {
        if (isDownloading) {
          await Future.delayed(Duration(milliseconds: 10));
        }
        imageBytes = await getDownloadedMedia(
          content.downloadToken,
          current.messageOtherId!,
          current.contactId,
        );
      } while (isDownloading && imageBytes == null);

      isDownloading = false;

      if (imageBytes == null) {
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
              bottom: showShortReactions ? 130 : 90,
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
                            sendTextMessage(widget.userId, emoji);
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
                    IconButton.outlined(
                      icon: FaIcon(FontAwesomeIcons.camera),
                      onPressed: () async {
                        context
                            .read<SendNextMediaTo>()
                            .updateSendNextMediaTo(widget.userId.toInt());
                        globalUpdateOfHomeViewPageIndex(0);
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all<EdgeInsets>(
                          EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      icon: SizedBox(
                        width: 40,
                        height: 40,
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
                        // context.read<SendNextMediaTo>().updateSendNextMediaTo(
                        //     widget.otherUser.userId.toInt());
                        // globalUpdateOfHomeViewPageIndex(0);
                        // Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all<EdgeInsets>(
                          EdgeInsets.symmetric(vertical: 10, horizontal: 30),
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
                            return ChatItemDetailsView(widget.userId);
                          }),
                        );
                      },
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all<EdgeInsets>(
                          EdgeInsets.symmetric(vertical: 10, horizontal: 30),
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
