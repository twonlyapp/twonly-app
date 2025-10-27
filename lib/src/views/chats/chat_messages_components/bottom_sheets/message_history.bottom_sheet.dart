import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_list_entry.dart';

class MessageHistoryView extends StatelessWidget {
  const MessageHistoryView({
    required this.message,
    required this.group,
    required this.changes,
    super.key,
  });

  final Message message;
  final Group group;
  final List<MessageHistory> changes;

  @override
  Widget build(BuildContext context) {
    final json = message.toJson();
    json['createdAt'] = message.modifiedAt;
    final currentMessage = Message.fromJson(json);
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.zero,
        height: 450,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          color: context.color.surface,
          boxShadow: const [
            BoxShadow(
              blurRadius: 10.9,
              color: Color.fromRGBO(0, 0, 0, 0.1),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.grey,
              ),
              height: 3,
              width: 60,
            ),
            Expanded(
              child: ListView(
                children: [
                  ChatListEntry(
                    group: group,
                    message: currentMessage,
                    hideReactions: true,
                  ),
                  ...changes.map(
                    (change) {
                      final json = message.toJson();
                      json['content'] = change.content;
                      json['createdAt'] = change.createdAt;
                      final msgChanged = Message.fromJson(json);
                      return ChatListEntry(
                        group: group,
                        message: msgChanged,
                        hideReactions: true,
                      );
                    },
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
