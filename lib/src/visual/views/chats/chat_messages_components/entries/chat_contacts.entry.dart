import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/key_verification.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/visual/components/add_contact_dialog.comp.dart';
import 'package:twonly/src/visual/elements/better_text.element.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_unknown.entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';

class ChatContactsEntry extends StatefulWidget {
  const ChatContactsEntry({
    required this.message,
    required this.borderRadius,
    required this.info,
    this.contactsById,
    super.key,
  });

  final Message message;
  final BorderRadiusGeometry borderRadius;
  final BubbleInfo info;
  final Map<int, Contact>? contactsById;

  @override
  State<ChatContactsEntry> createState() => _ChatContactsEntryState();
}

class _ChatContactsEntryState extends State<ChatContactsEntry> {
  /// Decoded once per message rather than on every rebuild.
  AdditionalMessageData? _data;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(ChatContactsEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.additionalMessageData !=
        widget.message.additionalMessageData) {
      _decode();
    }
  }

  void _decode() {
    if (widget.message.additionalMessageData == null) {
      _data = null;
      return;
    }
    try {
      _data = AdditionalMessageData.fromBuffer(
        widget.message.additionalMessageData!,
      );
    } catch (e) {
      _data = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    // Never collapse to nothing: a message row exists either way, so an
    // unreadable payload has to stay visible instead of leaving a phantom
    // bubble in the chat.
    if (data == null || data.contacts.isEmpty) {
      return const ChatUnknownEntry();
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.8,
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
                contactsById: widget.contactsById,
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
    this.contactsById,
  });

  final SharedContact contact;
  final Message message;
  final Map<int, Contact>? contactsById;

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
      final userdata = await RustApi.getUserById(
        userId: widget.contact.userId.toInt(),
      );

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
          userId: Value(userdata.userId),
          requested: const Value(false),
          blocked: const Value(false),
          deletedByUser: const Value(false),
        ),
      );

      if (added > 0) {
        await RustApi.tryRequestContactById(
          contactId: userdata.userId,
          expectedPublicKey: userdata.publicIdentityKey,
        );
      }

      await KeyVerificationService.verifySharedContact(
        contactId: userdata.userId,
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
    if (widget.contactsById != null) {
      return _buildContactRow(
        widget.contactsById![widget.contact.userId.toInt()],
      );
    }
    return StreamBuilder<Contact?>(
      stream: twonlyDB.contactsDao.watchContact(widget.contact.userId.toInt()),
      builder: (context, snapshot) {
        return _buildContactRow(snapshot.data);
      },
    );
  }

  Widget _buildContactRow(Contact? contactInDb) {
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
  }
}
