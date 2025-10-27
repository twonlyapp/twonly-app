import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_list_entry.dart';

class MessageInfoView extends StatefulWidget {
  const MessageInfoView({
    required this.message,
    required this.group,
    super.key,
  });

  final Message message;
  final Group group;

  @override
  State<MessageInfoView> createState() => _MessageInfoViewState();
}

class _MessageInfoViewState extends State<MessageInfoView> {
  @override
  void initState() {
    initAsync();
    super.initState();
  }

  Future<void> initAsync() async {
    // watch message edit history
    // watch message actions
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: ChatListEntry(
                group: widget.group,
                galleryItems: const [],
                prevMessage: null,
                message: widget.message,
                disableContextMenu: true,
                nextMessage: null,
                onResponseTriggered: () {},
                scrollToMessage: (_) {},
              ),
            ),
            Row(
              children: [
                const Text('Versendet'),
                const SizedBox(width: 13),
                Text(formatDateTime(context, widget.message.createdAt)),
              ],
            ),
            // Row(
            //   children: [
            //     Text("Empfangen"),
            //     SizedBox(width: 13),
            //     Text(formatDateTime(context, widget.message.ackByUser)),
            //   ],
            // )
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            const Text('Zugestelt an'),
          ],
        ),
      ),
    );
  }
}
