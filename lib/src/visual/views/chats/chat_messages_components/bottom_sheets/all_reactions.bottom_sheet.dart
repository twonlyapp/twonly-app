import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/database/reactions.dart' as rust_reactions;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/reactions/table.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';

class AllReactionsView extends StatefulWidget {
  const AllReactionsView({required this.message, super.key});

  final StoredMessage message;

  @override
  State<AllReactionsView> createState() => _AllReactionsViewState();
}

class _AllReactionsViewState extends State<AllReactionsView> {
  StreamSubscription<List<(StoredReaction, Contact?)>>? reactionsSub;
  List<(StoredReaction, Contact?)> reactionsUsers = [];

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  void dispose() {
    reactionsSub?.cancel();
    super.dispose();
  }

  Future<void> initAsync() async {
    final stream = watchRustDatabase(
      (control) => rust_reactions
          .watchReactionsWithContacts(
            message: widget.message.messageId,
            control: control,
          )
          .map(reactionsWithContacts),
    );

    reactionsSub = stream.listen((update) {
      if (!mounted) return;
      setState(() {
        reactionsUsers = update;
      });
    });
    setState(() {});
  }

  Future<void> removeReaction(String emoji) async {
    await rust_reactions.updateOwnReaction(
      message: widget.message.messageId,
      emoji: emoji,
      remove: true,
      transaction: currentDatabaseSession(),
    );
    await RustApi.sendEncryptedContentToGroup(
      groupId: widget.message.groupId,
      content: pb.EncryptedContent(
        reaction: pb.EncryptedContent_Reaction(
          targetMessageId: widget.message.messageId,
          emoji: emoji,
          remove: true,
        ),
      ).writeToBuffer(),
      onlySendIfNoReceiptsAreOpen: false,
    );
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
                children: reactionsUsers.map((entry) {
                  return GestureDetector(
                    key: ValueKey(entry),
                    onTap: (entry.$2 != null)
                        ? null
                        : () {
                            removeReaction(entry.$1.emoji);
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 30,
                      ),
                      color: Colors.transparent,
                      margin: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          AvatarIcon(
                            contactId: entry.$2?.userId,
                            myAvatar: entry.$2 == null,
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
                          if (EmojiAnimationComp.animatedIcons.containsKey(
                            entry.$1.emoji,
                          ))
                            SizedBox(
                              height: 25,
                              child: EmojiAnimationComp(emoji: entry.$1.emoji),
                            )
                          else
                            SizedBox(
                              height: 24,
                              child: Center(
                                child: Text(
                                  entry.$1.emoji,
                                  style: const TextStyle(fontSize: 22),
                                  strutStyle: const StrutStyle(
                                    forceStrutHeight: true,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          // Text(
                          //   entry.$1.emoji,
                          //   style: const TextStyle(fontSize: 25),
                          // ),
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
