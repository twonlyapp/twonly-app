import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/views/chats/chat_item_details_view.dart';
import 'package:twonly/src/views/chats/components/in_chat_media_viewer.dart';
import 'package:twonly/src/views/components/animate_icon.dart';
import 'package:twonly/src/views/components/better_text.dart';
import 'package:twonly/src/views/components/message_send_state_icon.dart';
import 'package:twonly/src/views/chats/components/sliding_response.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api/media_received.dart' as received;
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/views/chats/media_viewer_view.dart';

class ChatListEntry extends StatelessWidget {
  const ChatListEntry(
    this.message,
    this.contact,
    this.lastMessageFromSameUser,
    this.textReactions,
    this.otherReactions, {
    super.key,
    required this.onResponseTriggered,
  });
  final Message message;
  final Contact contact;
  final bool lastMessageFromSameUser;
  final List<Message> textReactions;
  final List<Message> otherReactions;
  final Function(Message) onResponseTriggered;

  Widget getReactionRow() {
    List<Widget> children = [];
    bool hasOneTextReaction = false;
    bool hasOneReopened = false;
    for (final reaction in otherReactions) {
      MessageContent? content = MessageContent.fromJson(
          reaction.kind, jsonDecode(reaction.contentJson!));

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
    for (final reaction in textReactions) {
      MessageContent? content = MessageContent.fromJson(
          reaction.kind, jsonDecode(reaction.contentJson!));

      if (content is TextMessageContent) {
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

        Color color = getMessageColor(reaction);

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
                color: color,
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
            vertical: 4,
            horizontal: 10,
          ),
          child: EmojiAnimation(emoji: content.text),
        );
      } else {
        child = Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          decoration: BoxDecoration(
            color: getMessageColor(message),
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
          if (await received.existsMediaFile(message.messageId, "png")) {
            await encryptAndSendMessageAsync(
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
                  return MediaViewerView(contact, initialMessage: message);
                }),
              );
            } else if (message.downloadState == DownloadState.pending) {
              received.startDownloadMedia(message, true);
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
            SlidingResponse(
              child: Stack(
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
              onResponseTriggered: () {
                onResponseTriggered(message);
              },
            ),
            getTextResponseColumns(context, !right)
          ],
        ),
      ),
    );
  }
}
