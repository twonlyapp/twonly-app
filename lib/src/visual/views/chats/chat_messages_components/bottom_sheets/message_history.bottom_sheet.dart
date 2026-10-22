import 'package:flutter/material.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/chat_list_entry.dart';

class MessageHistoryView extends StatelessWidget {
  const MessageHistoryView({
    required this.message,
    required this.group,
    required this.changes,
    super.key,
  });

  final StoredMessage message;
  final Group group;
  final List<MessageHistory> changes;

  @override
  Widget build(BuildContext context) {
    final currentMessage = message.copyWith(
      createdAt: message.modifiedAt ?? message.createdAt,
    );
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
          boxShadow: [
            BoxShadow(
              blurRadius: 10.9,
              color: context.color.shadow.withValues(alpha: 0.1),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: context.color.outline,
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
                      final msgChanged = message.copyWith(
                        content: NullableText(value: change.content),
                        createdAt: change.createdAt,
                      );
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
