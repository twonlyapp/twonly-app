import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/user_discovery.dart'
    as rust_user_discovery;
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/core/database/app/user_discovery/table.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';

class ChatAskAFriendEntry extends StatefulWidget {
  const ChatAskAFriendEntry({
    required this.message,
    required this.borderRadius,
    required this.info,
    this.contactsById,
    super.key,
  });

  final StoredMessage message;
  final BorderRadiusGeometry borderRadius;
  final BubbleInfo info;
  final Map<int, Contact>? contactsById;

  @override
  State<ChatAskAFriendEntry> createState() => _ChatAskAFriendEntryState();
}

class _ChatAskAFriendEntryState extends State<ChatAskAFriendEntry> {
  bool _isLoading = false;
  String? _username;
  bool _isSent = false;
  AdditionalMessageData? _data;

  @override
  void initState() {
    super.initState();
    _isSent = widget.message.senderId == null;
    if (widget.message.additionalMessageData != null) {
      try {
        _data = AdditionalMessageData.fromBuffer(
          widget.message.additionalMessageData!,
        );
      } catch (e) {
        _data = null;
      }
    }
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (_data == null || !_data!.hasAskAboutUserId()) return;
    final userId = _data!.askAboutUserId.toInt();
    final sharedContact = widget.contactsById?[userId];
    if (sharedContact != null) {
      _username = sharedContact.displayName ?? sharedContact.username;
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSent) {
        // Try getting from contacts
        final contact = await rust_contacts.getContact(
          id: userId,
          transaction: currentDatabaseSession(),
        );
        if (contact != null) {
          _username = contact.displayName ?? contact.username;
        } else {
          // Try getting from announced users
          final announced = await rust_user_discovery.getDiscoveryAnnouncement(
            id: userId,
            transaction: currentDatabaseSession(),
          );
          if (announced != null && announced.username != null) {
            _username = announced.username;
          }
        }
      } else {
        // Receiver side: try contacts first
        final contact = await rust_contacts.getContact(
          id: userId,
          transaction: currentDatabaseSession(),
        );
        if (contact != null) {
          _username = contact.displayName ?? contact.username;
        } else {
          // Fetch from API
          FrbUserData? userdata;
          try {
            userdata = await RustApi.getUserById(userId: userId);
          } catch (_) {}
          if (userdata != null) {
            _username = utf8.decode(userdata.username);
          }
        }
      }
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

  Future<void> _hideUser() async {
    if (_data == null || !_data!.hasAskAboutUserId()) return;
    await rust_user_discovery.updateDiscoveryAnnouncement(
      id: _data!.askAboutUserId.toInt(),
      patch: const UserDiscoveryAnnouncedUserPatch(isHidden: true),
      transaction: currentDatabaseSession(),
    );
  }

  Future<void> _requestUser() async {
    if (_data == null || !_data!.hasAskAboutUserId()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final userId = _data!.askAboutUserId.toInt();
      FrbUserData? userdata;
      try {
        userdata = await RustApi.getUserById(userId: userId);
      } catch (_) {}
      if (userdata != null) {
        await rust_contacts.upsertContact(
          patch: ContactPatch(
            username: utf8.decode(userdata.username),
            userId: userdata.userId,
            requested: false,
            blocked: false,
            deletedByUser: false,
            joinedAt: userdata.joinedAt == null
                ? null
                : NullableInt(
                    value: databaseNullableSeconds(
                      DateTime.fromMillisecondsSinceEpoch(
                        userdata.joinedAt! * Duration.millisecondsPerSecond,
                        isUtc: true,
                      ),
                    ),
                  ),
          ),
          transaction: currentDatabaseSession(),
        );
        await RustApi.tryRequestContactById(
          contactId: userdata.userId,
          expectedPublicKey: userdata.publicIdentityKey,
        );
      }
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
    if (_data == null || !_data!.hasAskAboutUserId()) {
      return const SizedBox.shrink();
    }

    final userId = _data!.askAboutUserId.toInt();

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: widget.info.color,
        borderRadius: widget.borderRadius,
      ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<Contact?>(
              stream: widget.contactsById == null
                  ? watchRustDatabase(
                      (control) => rust_contacts.watchContacts(
                        input: db_contacts.ContactQuery(
                          filter: db_contacts.ContactFilter.ids,
                          ids: Int64List.fromList([userId].toList()),
                        ),
                        control: control,
                      ),
                    ).map((rows) => rows.isEmpty ? null : rows.single)
                  : Stream.value(widget.contactsById![userId]),
              builder: (context, snapshot) {
                final contactInDb = snapshot.data;
                return GestureDetector(
                  onTap: () {
                    if (contactInDb != null) {
                      context.push(Routes.profileContact(userId));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AvatarIcon(
                          contactId: userId,
                          contacts: widget.contactsById?[userId] == null
                              ? null
                              : [widget.contactsById![userId]!],
                          fontSize: 12,
                        ),
                        const SizedBox(width: 8),
                        if (_isLoading && _username == null)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else if (_username != null)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                _username!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: widget.info.textColor,
                                ),
                              ),
                            ),
                          )
                        else
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                context.lang.chatAskAFriendUnknownUser(
                                  userId.toString(),
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: widget.info.textColor,
                                ),
                              ),
                            ),
                          ),
                        if (contactInDb != null) ...[
                          Opacity(
                            opacity: 0.5,
                            child: FaIcon(
                              FontAwesomeIcons.chevronRight,
                              size: 10,
                              color: widget.info.textColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else ...[
                          const SizedBox(width: 4),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            if (!_isSent) ...[
              const SizedBox(height: 12),
              Text(
                context.lang.chatAskAFriendReceivedDescription,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.info.textColor,
                ),
              ),
            ] else ...[
              StreamBuilder<Contact?>(
                stream: widget.contactsById == null
                    ? watchRustDatabase(
                        (control) => rust_contacts.watchContacts(
                          input: db_contacts.ContactQuery(
                            filter: db_contacts.ContactFilter.ids,
                            ids: Int64List.fromList([userId].toList()),
                          ),
                          control: control,
                        ),
                      ).map((rows) => rows.isEmpty ? null : rows.single)
                    : Stream.value(widget.contactsById![userId]),
                builder: (context, contactSnapshot) {
                  final contactInDb = contactSnapshot.data;
                  if (contactInDb != null) {
                    return Text(
                      context.lang.chatAskAFriendAddedDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.info.textColor,
                      ),
                    );
                  }

                  return StreamBuilder<UserDiscoveryAnnouncedUser?>(
                    stream: watchRustDatabase(
                      (control) =>
                          rust_user_discovery.watchDiscoveryAnnouncement(
                            id: userId,
                            control: control,
                          ),
                    ),
                    builder: (context, userSnapshot) {
                      final announcedUser = userSnapshot.data;
                      if (announcedUser != null && announcedUser.isHidden) {
                        return const SizedBox.shrink();
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : _hideUser,
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            child: Text(
                              context.lang.chatAskAFriendHide,
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.info.textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ).merge(secondaryGreyButtonStyle(context)),
                            onPressed: _isLoading ? null : _requestUser,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator.adaptive(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    context.lang.chatAskAFriendRequest,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
