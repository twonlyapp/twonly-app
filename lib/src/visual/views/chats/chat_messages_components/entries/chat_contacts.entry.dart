import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/api/utils.api.dart';
import 'package:twonly/src/services/key_verification.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/visual/components/add_contact_dialog.comp.dart';
import 'package:twonly/src/visual/elements/better_text.element.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';

class ChatContactsEntry extends StatefulWidget {
  const ChatContactsEntry({
    required this.message,
    required this.borderRadius,
    required this.info,
    super.key,
  });

  final Message message;
  final BorderRadiusGeometry borderRadius;
  final BubbleInfo info;

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

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.info.color,
        borderRadius: widget.borderRadius,
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
    if (widget.contact.userId.toInt() == userService.currentUser.userId) {
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
      final userdata = await apiService.getUserById(
        widget.contact.userId.toInt(),
      );
      if (userdata == null) return;

      final username = utf8.decode(userdata.username);

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      final shouldRequest = await AddContactDialog.show(context, username);
      if (shouldRequest != true) return;

      setState(() {
        _isLoading = true;
      });

      final added = await twonlyDB.contactsDao.insertOnConflictUpdate(
        ContactsCompanion(
          username: Value(username),
          userId: Value(userdata.userId.toInt()),
          requested: const Value(false),
          blocked: const Value(false),
          deletedByUser: const Value(false),
        ),
      );

      if (added > 0) await importSignalContactAndCreateRequest(userdata);

      await KeyVerificationService.verifySharedContact(
        contactId: userdata.userId.toInt(),
        sharedPublicIdentityKey: widget.contact.publicIdentityKey,
        senderId: widget.message.senderId!,
      );
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
        final isAdded =
            contactInDb != null ||
            widget.contact.userId.toInt() == userService.currentUser.userId;

        return GestureDetector(
          onTap: _isLoading ? null : () => _onContactClick(isAdded),
          child: ColoredBox(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
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
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
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
