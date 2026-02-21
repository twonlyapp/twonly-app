import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/views/chats/chat_messages_components/entries/common.dart';
import 'package:twonly/src/views/components/better_text.dart';

class ChatContactsEntry extends StatefulWidget {
  const ChatContactsEntry({
    required this.message,
    super.key,
  });

  final Message message;

  @override
  State<ChatContactsEntry> createState() => _ChatContactsEntryState();
}

class _ChatContactsEntryState extends State<ChatContactsEntry> {
  @override
  Widget build(BuildContext context) {
    AdditionalMessageData? data;

    if (widget.message.additionalMessageData != null) {
      try {
        data = AdditionalMessageData.fromBuffer(
          widget.message.additionalMessageData!,
        );
      } catch (e) {
        data = null;
      }
    }

    if (data == null || data.contacts.isEmpty) {
      return const SizedBox.shrink();
    }

    final info = getBubbleInfo(
      context,
      widget.message,
      null,
      null,
      null,
      0,
    );

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: info.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < data.contacts.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              _ContactRow(
                contact: data.contacts[i],
                message: widget.message,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatefulWidget {
  const _ContactRow({
    required this.contact,
    required this.message,
  });

  final SharedContact contact;
  final Message message;

  @override
  State<_ContactRow> createState() => _ContactRowState();
}

class _ContactRowState extends State<_ContactRow> {
  bool _isLoading = false;

  Future<void> _onContactClick(bool isAdded) async {
    if (widget.contact.userId.toInt() == gUser.userId) {
      await context.push(Routes.settingsProfile);
      return;
    }
    if (isAdded) {
      await context.push(Routes.profileContact(widget.contact.userId.toInt()));
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final userdata =
          await apiService.getUserById(widget.contact.userId.toInt());
      if (userdata == null) return;

      var verified = false;
      if (userdata.publicIdentityKey == widget.contact.publicIdentityKey) {
        final sender =
            await twonlyDB.contactsDao.getContactById(widget.message.senderId!);
        // in case the sender is verified and the public keys are the same, this trust can be transferred
        verified = sender != null && sender.verified;
      }

      final added = await twonlyDB.contactsDao.insertOnConflictUpdate(
        ContactsCompanion(
          username: Value(utf8.decode(userdata.username)),
          userId: Value(userdata.userId.toInt()),
          requested: const Value(false),
          blocked: const Value(false),
          deletedByUser: const Value(false),
          verified: Value(
            verified,
          ),
        ),
      );

      if (added > 0) await importSignalContactAndCreateRequest(userdata);
    } catch (e) {
      Log.error(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Contact?>(
      stream: twonlyDB.contactsDao.watchContact(widget.contact.userId.toInt()),
      builder: (context, snapshot) {
        final contactInDb = snapshot.data;
        final isAdded = contactInDb != null ||
            widget.contact.userId.toInt() == gUser.userId;

        return GestureDetector(
          onTap: _isLoading ? null : () => _onContactClick(isAdded),
          child: ColoredBox(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.user,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: BetterText(
                      text: widget.contact.displayName,
                      textColor: Colors.white,
                    ),
                  ),
                  if (widget.message.senderId != null && !isAdded) ...[
                    const Spacer(),
                    const SizedBox(width: 8),
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const FaIcon(
                        FontAwesomeIcons.userPlus,
                        color: Colors.white,
                        size: 16,
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
