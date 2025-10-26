import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';

class AllReactionsView extends StatefulWidget {
  const AllReactionsView({required this.message, super.key});

  final Message message;

  @override
  State<AllReactionsView> createState() => _AllReactionsViewState();
}

class _AllReactionsViewState extends State<AllReactionsView> {
  StreamSubscription<List<(Reaction, Contact?)>>? reactionsSub;
  List<(Reaction, Contact?)> reactionsUsers = [];

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  @override
  void dispose() {
    reactionsSub?.cancel();
    super.dispose();
  }

  Future<void> initAsync() async {
    final stream = twonlyDB.reactionsDao
        .watchReactionWithContacts(widget.message.messageId);

    reactionsSub = stream.listen((update) {
      setState(() {
        reactionsUsers = update;
      });
    });
    setState(() {});
  }

  Future<void> removeReaction() async {
    await twonlyDB.reactionsDao
        .updateMyReaction(widget.message.messageId, null);
    await sendCipherTextToGroup(
      widget.message.groupId,
      pb.EncryptedContent(
        reaction: pb.EncryptedContent_Reaction(
          targetMessageId: widget.message.messageId,
          remove: true,
        ),
      ),
      null,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.zero,
        height: 400,
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
                children: reactionsUsers.map((entry) {
                  return GestureDetector(
                    onTap: (entry.$2 != null) ? null : removeReaction,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 30,
                      ),
                      margin: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          AvatarIcon(
                            contact: entry.$2,
                            userData: (entry.$2 == null) ? gUser : null,
                            fontSize: 15,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (entry.$2 == null)
                                      ? context.lang.you
                                      : getContactDisplayName(entry.$2!),
                                  style: const TextStyle(fontSize: 17),
                                ),
                                if (entry.$2 == null)
                                  Text(
                                    context.lang.tabToRemoveEmoji,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            entry.$1.emoji,
                            style: const TextStyle(fontSize: 25),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
