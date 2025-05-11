import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/providers/api/media_send.dart';
import 'package:twonly/src/views/components/animate_icon.dart';
import 'package:twonly/src/views/components/better_text.dart';
import 'package:twonly/src/views/components/initialsavatar.dart';
import 'package:twonly/src/views/components/message_send_state_icon.dart';
import 'package:twonly/src/views/components/verified_shield.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api/media_received.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/views/camera/camera_send_to_view.dart';
import 'package:twonly/src/views/chats/media_viewer_view.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/contact/contact_view.dart';
import 'package:video_player/video_player.dart';

class ChatMediaViewerFullScreen extends StatelessWidget {
  const ChatMediaViewerFullScreen({super.key, required this.message});
  final Message message;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: InChatMediaViewer(message: message, isInFullscreen: true),
        ),
      ),
    );
  }
}

class InChatMediaViewer extends StatefulWidget {
  const InChatMediaViewer(
      {super.key, required this.message, this.isInFullscreen = false});

  final Message message;
  final bool isInFullscreen;

  @override
  State<InChatMediaViewer> createState() => _InChatMediaViewerState();
}

class _InChatMediaViewerState extends State<InChatMediaViewer> {
  File? image;
  File? video;
  bool isMounted = true;
  bool mirrorVideo = false;
  VideoPlayerController? videoController;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future initAsync() async {
    if (!widget.message.mediaStored) return;
    bool isSend = widget.message.messageOtherId == null;
    final basePath = await getMediaFilePath(
      isSend ? widget.message.mediaUploadId! : widget.message.messageId,
      isSend ? "send" : "received",
    );
    if (!isMounted) return;
    final videoPath = File("$basePath.mp4");
    final imagePath = File("$basePath.png");
    if (videoPath.existsSync() && widget.message.contentJson != null) {
      MessageContent? content = MessageContent.fromJson(
          MessageKind.media, jsonDecode(widget.message.contentJson!));
      if (content is MediaMessageContent) {
        mirrorVideo = content.mirrorVideo;
      }
      videoController = VideoPlayerController.file(videoPath);
      videoController?.initialize().then((_) {
        if (!widget.isInFullscreen) {
          videoController!.setVolume(0);
        }
        videoController!.play();
      });

      setState(() {
        image = imagePath;
      });
    }
    if (imagePath.existsSync()) {
      setState(() {
        image = imagePath;
      });
    } else {
      print("Not found: $imagePath");
    }
  }

  @override
  void dispose() {
    super.dispose();
    isMounted = false;
    videoController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.isInFullscreen) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return ChatMediaViewerFullScreen(message: widget.message);
          }),
        );
      },
      child: Stack(
        children: [
          if (image != null) Image.file(image!),
          if (videoController != null)
            Positioned.fill(
              child: Transform.flip(
                flipX: mirrorVideo,
                child: VideoPlayer(videoController!),
              ),
            ),
          if (image == null && video == null)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: MessageSendStateIcon(
                [widget.message],
                mainAxisAlignment: MainAxisAlignment.center,
              ),
            )
        ],
      ),
    );
  }
}

class ChatListEntry extends StatelessWidget {
  const ChatListEntry(
      this.message, this.contact, this.lastMessageFromSameUser, this.reactions,
      {super.key});
  final Message message;
  final Contact contact;
  final bool lastMessageFromSameUser;
  final List<Message> reactions;

  Widget getReactionRow() {
    List<Widget> children = [];
    bool hasOneTextReaction = false;
    // bool hasOneStored = false;
    bool hasOneReopened = false;
    for (final reaction in reactions) {
      MessageContent? content = MessageContent.fromJson(
          reaction.kind, jsonDecode(reaction.contentJson!));

      // if (content is StoredMediaFileContent || message.mediaStored) {
      //   if (hasOneStored) continue;
      //   hasOneStored = true;
      //   children.add(
      //     Expanded(
      //       child: Align(
      //         alignment: Alignment.bottomRight,
      //         child: Padding(
      //           padding: EdgeInsets.only(right: 3),
      //           child: FaIcon(
      //             FontAwesomeIcons.floppyDisk,
      //             size: 12,
      //             color: Colors.blue,
      //           ),
      //         ),
      //       ),
      //     ),
      //   );
      // }

      if (content is ReopenedMediaFileContent) {
        if (hasOneReopened) continue;
        hasOneReopened = true;
        children.add(
          Expanded(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(right: 3),
                child: FaIcon(
                  FontAwesomeIcons.repeat,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      }
      // only show one reaction
      if (hasOneTextReaction) continue;

      if (content is TextMessageContent) {
        hasOneTextReaction = true;
        if (!isEmoji(content.text)) continue;
        late Widget child;
        if (EmojiAnimation.animatedIcons.containsKey(content.text)) {
          child = SizedBox(
            height: 18,
            child: EmojiAnimation(emoji: content.text),
          );
        } else {
          child = Text(content.text, style: TextStyle(fontSize: 14));
        }
        children.insert(
          0,
          Padding(
            padding: EdgeInsets.only(left: 3),
            child: child,
          ),
        );
      }
    }

    if (children.isEmpty) return Container();

    return Row(
      mainAxisAlignment: message.messageOtherId == null
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      children: children,
    );
  }

  Widget getTextResponseColumns(BuildContext context, bool right) {
    List<Widget> children = [];
    for (final reaction in reactions) {
      MessageContent? content = MessageContent.fromJson(
          reaction.kind, jsonDecode(reaction.contentJson!));

      if (content is TextMessageContent) {
        if (content.text.length <= 1) continue;
        if (isEmoji(content.text)) continue;
        var entries = [
          FaIcon(
            FontAwesomeIcons.reply,
            size: 10,
          ),
          SizedBox(width: 5),
          Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.5,
              ),
              child: Text(
                content.text,
                style: TextStyle(fontSize: 14),
                textAlign: right ? TextAlign.left : TextAlign.right,
              )),
        ];
        if (!right) {
          entries = entries.reversed.toList();
        }

        children.insert(
          0,
          Container(
            padding: EdgeInsets.only(top: 5, bottom: 0, right: 10, left: 10),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: EdgeInsets.symmetric(vertical: 1, horizontal: 10),
              decoration: BoxDecoration(
                color: right
                    ? const Color.fromARGB(107, 124, 77, 255)
                    : const Color.fromARGB(83, 68, 137, 255),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: entries,
              ),
            ),
          ),
        );
      }
    }

    if (children.isEmpty) return Container();

    return Column(
      // mainAxisAlignment: message.messageOtherId == null
      //     ? MainAxisAlignment.start
      //     : MainAxisAlignment.end,
      crossAxisAlignment:
          right ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool right = message.messageOtherId == null;

    MessageContent? content =
        MessageContent.fromJson(message.kind, jsonDecode(message.contentJson!));

    Widget child = Container();

    if (content is TextMessageContent) {
      if (EmojiAnimation.supported(content.text)) {
        child = child = Container(
          constraints: BoxConstraints(
            maxWidth: 100,
          ),
          padding: EdgeInsets.symmetric(
              vertical: 4, horizontal: 10), // Add some padding around the text
          child: EmojiAnimation(emoji: content.text),
        );
      } else {
        child = Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          decoration: BoxDecoration(
            color: right
                ? const Color.fromARGB(107, 124, 77, 255)
                : const Color.fromARGB(83, 68, 137, 255),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: BetterText(text: content.text),
        );
      }
    } else if (content is MediaMessageContent) {
      Color color = getMessageColorFromType(
        content,
        context,
      );

      child = GestureDetector(
        onDoubleTap: () async {
          if (message.openedAt == null && message.messageOtherId != null ||
              message.mediaStored) {
            return;
          }
          if (await existsMediaFile(message.messageId, "png")) {
            encryptAndSendMessage(
              null,
              contact.userId,
              MessageJson(
                kind: MessageKind.reopenedMedia,
                messageId: message.messageId,
                content: ReopenedMediaFileContent(
                  messageId: message.messageOtherId!,
                ),
                timestamp: DateTime.now(),
              ),
              pushKind: PushKind.reopenedMedia,
            );
            await twonlyDatabase.messagesDao.updateMessageByMessageId(
              message.messageId,
              MessagesCompanion(openedAt: Value(null)),
            );
          }
        },
        onTap: () {
          if (message.kind == MessageKind.media) {
            if (message.downloadState == DownloadState.downloaded &&
                message.openedAt == null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return MediaViewerView(contact);
                }),
              );
            } else if (message.downloadState == DownloadState.pending) {
              startDownloadMedia(message, true);
            }
          }
        },
        child: Container(
          width: 150,
          decoration: BoxDecoration(
            border: Border.all(
              color: color,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InChatMediaViewer(message: message),
            ),
          ),
        ),
      );
    } else if (message.kind == MessageKind.storedMediaFile) {
      child = Container(
        padding: EdgeInsets.all(5),
        width: 150,
        decoration: BoxDecoration(
          border: Border.all(
            color:
                getMessageColorFromType(TextMessageContent(text: ""), context),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: MessageSendStateIcon(
            [message],
            mainAxisAlignment:
                right ? MainAxisAlignment.center : MainAxisAlignment.center,
          ),
        ),
      );
    }

    return Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: lastMessageFromSameUser
            ? EdgeInsets.only(top: 5, bottom: 0, right: 10, left: 10)
            : EdgeInsets.only(top: 5, bottom: 20, right: 10, left: 10),
        child: Column(
          mainAxisAlignment:
              right ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment:
              right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: right ? Alignment.centerRight : Alignment.centerLeft,
              children: [
                child,
                Positioned(
                  bottom: 5,
                  left: 5,
                  right: 5,
                  child: getReactionRow(),
                ),
              ],
            ),
            getTextResponseColumns(context, !right)
          ],
        ),
      ),
    );
  }
}

/// Displays detailed information about a SampleItem.
class ChatItemDetailsView extends StatefulWidget {
  const ChatItemDetailsView(this.contact, {super.key});

  final Contact contact;

  @override
  State<ChatItemDetailsView> createState() => _ChatItemDetailsViewState();
}

class _ChatItemDetailsViewState extends State<ChatItemDetailsView> {
  TextEditingController newMessageController = TextEditingController();
  HashSet<int> alreadyReportedOpened = HashSet<int>();
  late Contact user;
  String currentInputText = "";
  late StreamSubscription<Contact> userSub;
  late StreamSubscription<List<Message>> messageSub;
  List<Message> messages = [];
  Map<int, List<Message>> reactionsToMyMessages = {};
  Map<int, List<Message>> reactionsToOtherMessages = {};

  @override
  void initState() {
    super.initState();
    user = widget.contact;
    initStreams();
  }

  @override
  void dispose() {
    super.dispose();
    userSub.cancel();
    messageSub.cancel();
  }

  Future initStreams() async {
    await twonlyDatabase.messagesDao.removeOldMessages();
    Stream<Contact> contact =
        twonlyDatabase.contactsDao.watchContact(widget.contact.userId);
    userSub = contact.listen((contact) {
      setState(() {
        user = contact;
      });
    });

    Stream<List<Message>> msgStream =
        twonlyDatabase.messagesDao.watchAllMessagesFrom(widget.contact.userId);
    messageSub = msgStream.listen((msgs) {
      // if (!context.mounted) return;
      if (Platform.isAndroid) {
        flutterLocalNotificationsPlugin.cancel(widget.contact.userId);
      } else {
        flutterLocalNotificationsPlugin.cancelAll();
      }
      List<Message> displayedMessages = [];
      // should be cleared
      Map<int, List<Message>> tmpReactionsToMyMessages = {};
      Map<int, List<Message>> tmpTeactionsToOtherMessages = {};

      List<int> openedMessageOtherIds = [];
      for (Message msg in msgs) {
        if (msg.kind == MessageKind.textMessage &&
            msg.messageOtherId != null &&
            msg.openedAt == null) {
          openedMessageOtherIds.add(msg.messageOtherId!);
        }

        if (msg.responseToMessageId != null) {
          if (!tmpReactionsToMyMessages.containsKey(msg.responseToMessageId!)) {
            tmpReactionsToMyMessages[msg.responseToMessageId!] = [msg];
          } else {
            tmpReactionsToMyMessages[msg.responseToMessageId!]!.add(msg);
          }
        } else if (msg.responseToOtherMessageId != null) {
          if (!tmpTeactionsToOtherMessages
              .containsKey(msg.responseToOtherMessageId!)) {
            tmpTeactionsToOtherMessages[msg.responseToOtherMessageId!] = [msg];
          } else {
            tmpTeactionsToOtherMessages[msg.responseToOtherMessageId!]!
                .add(msg);
          }
        } else {
          displayedMessages.add(msg);
        }
      }
      if (openedMessageOtherIds.isNotEmpty) {
        notifyContactAboutOpeningMessage(
            widget.contact.userId, openedMessageOtherIds);
      }
      twonlyDatabase.messagesDao
          .openedAllNonMediaMessages(widget.contact.userId);
      // should be fixed with that
      // if (!updated) {
      //   // The stream should be get an update, so only update the UI when all are opened
      setState(() {
        reactionsToMyMessages = tmpReactionsToMyMessages;
        reactionsToOtherMessages = tmpTeactionsToOtherMessages;
        messages = displayedMessages;
      });
      // }
    });
  }

  Future _sendMessage() async {
    if (newMessageController.text == "") return;
    await sendTextMessage(
      user.userId,
      TextMessageContent(
        text: newMessageController.text,
      ),
      PushKind.text,
    );
    newMessageController.clear();
    currentInputText = "";
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ContactView(widget.contact.userId);
            }));
          },
          child: Row(
            children: [
              ContactAvatar(
                contact: user,
                fontSize: 19,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Text(getContactDisplayName(user)),
                      SizedBox(width: 10),
                      VerifiedShield(user),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                reverse: true,
                itemBuilder: (context, i) {
                  bool lastMessageFromSameUser = false;
                  if (i > 0) {
                    lastMessageFromSameUser =
                        (messages[i - 1].messageOtherId == null &&
                                messages[i].messageOtherId == null) ||
                            (messages[i - 1].messageOtherId != null &&
                                messages[i].messageOtherId != null);
                  }
                  Message msg = messages[i];
                  List<Message> reactions = [];
                  if (reactionsToMyMessages.containsKey(msg.messageId)) {
                    reactions = reactionsToMyMessages[msg.messageId]!;
                  }
                  if (msg.messageOtherId != null &&
                      reactionsToOtherMessages
                          .containsKey(msg.messageOtherId!)) {
                    reactions = reactionsToOtherMessages[msg.messageOtherId!]!;
                  }
                  return ChatListEntry(
                    key: Key(msg.messageId.toString()),
                    msg,
                    user,
                    lastMessageFromSameUser,
                    reactions,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 30, left: 20, right: 20, top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: newMessageController,
                      onChanged: (value) {
                        currentInputText = value;
                        setState(() {});
                      },
                      onSubmitted: (_) {
                        _sendMessage();
                      },
                      decoration: inputTextMessageDeco(context),
                    ),
                  ),
                  SizedBox(width: 8),
                  (currentInputText != "")
                      ? IconButton(
                          icon: FaIcon(FontAwesomeIcons.solidPaperPlane),
                          onPressed: () {
                            _sendMessage();
                          },
                        )
                      : IconButton(
                          icon: FaIcon(FontAwesomeIcons.camera),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) {
                                return CameraSendToView(widget.contact);
                              },
                            ));
                          },
                        )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration inputTextMessageDeco(BuildContext context) {
  return InputDecoration(
    hintText: context.lang.chatListDetailInput,
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20.0),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20.0),
      borderSide: BorderSide(color: Colors.grey, width: 2.0),
    ),
  );
}
