import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/views/components/animate_icon.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api/media_received.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera/camera_send_to_view.dart';
import 'package:twonly/src/views/chats/chat_item_details_view.dart';

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

  // current image related
  Uint8List? imageBytes;
  DateTime? canBeSeenUntil;
  int maxShowTime = 999999;
  double progress = 0;
  bool isRealTwonly = false;
  bool isDownloading = false;
  bool showSendTextMessageInput = false;

  bool imageSaved = false;
  bool imageSaving = false;

  List<Message> allMediaFiles = [];
  late StreamSubscription<List<Message>> _subscription;
  TextEditingController textMessageController = TextEditingController();

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
      showSendTextMessageInput = false;
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
        // ignore: use_build_context_synchronously
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
      await startDownloadMedia(current, true);
    }


    load downloaded status from database

      notifyContactAboutOpeningMessage(
      message.contactId, [message.messageOtherId!]);
  twonlyDatabase.messagesDao.updateMessageByMessageId(
      message.messageId, MessagesCompanion(openedAt: Value(DateTime.now())));
    // do {
    //   if (isDownloading) {
    //     await Future.delayed(Duration(milliseconds: 10));
    //     if (!apiProvider.isConnected) break;
    //   }
    //   if (content.downloadToken == null) break;
    //   imageBytes = await getDownloadedMedia(current, content.downloadToken!);
    // } while (isDownloading && imageBytes == null);

    if twonly deleteMediaFile()




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

  Future onPressedSaveToGallery() async {
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
  }

  Widget bottomNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
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
            setState(() {
              showShortReactions = !showShortReactions;
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
            setState(() {
              showSendTextMessageInput = true;
              showShortReactions = true;
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
            await Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return CameraSendToView(widget.contact);
              },
            ));
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
            if (imageBytes != null && (canBeSeenUntil == null || progress >= 0))
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
                  requiredHeight: 80,
                  child: Image.memory(
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
                                    CircularProgressIndicator(strokeWidth: 2),
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
                              PushKind.reaction,
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
                userId: widget.contact.userId,
                responseToMessageId: allMediaFiles.first.messageOtherId!,
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
  const ReactionButtons(
      {super.key,
      required this.show,
      required this.userId,
      required this.responseToMessageId,
      required this.hide});

  final bool show;
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
      bottom: widget.show ? 100 : 90,
      left: widget.show ? 0 : 150,
      right: widget.show ? 0 : 150,
      curve: Curves.linearToEaseOut,
      child: AnimatedOpacity(
        opacity: widget.show ? 1.0 : 0.0, // Fade in/out
        duration: Duration(milliseconds: 150),
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
                          emoji: emoji,
                        ))
                    .toList(),
              ),
            if (secondRowEmojis.isNotEmpty) SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: firstRowEmojis
                  .map((emoji) => EmojiReactionWidget(
                        userId: widget.userId,
                        responseToMessageId: widget.responseToMessageId,
                        hide: widget.hide,
                        show: widget.show,
                        emoji: emoji,
                      ))
                  .toList(),
            ),
          ],
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
  final String emoji;

  const EmojiReactionWidget({
    super.key,
    required this.userId,
    required this.responseToMessageId,
    required this.hide,
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
            PushKind.reaction,
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
