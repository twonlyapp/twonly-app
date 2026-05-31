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
    super.key,
  });

  final Message message;
  final BorderRadiusGeometry borderRadius;
  final BubbleInfo info;

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
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSent) {
        // Try getting from contacts
        final contact = await twonlyDB.contactsDao.getContactById(userId);
        if (contact != null) {
          _username = contact.displayName ?? contact.username;
        } else {
          // Try getting from announced users
          final announced = await twonlyDB.userDiscoveryDao
              .getAnnouncedUserById(userId);
          if (announced != null && announced.username != null) {
            _username = announced.username;
          }
        }
      } else {
        // Receiver side: try contacts first
        final contact = await twonlyDB.contactsDao.getContactById(userId);
        if (contact != null) {
          _username = contact.displayName ?? contact.username;
        } else {
          // Fetch from API
          final userdata = await apiService.getUserById(userId);
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
    await twonlyDB.userDiscoveryDao.updateAnnouncedUser(
      _data!.askAboutUserId.toInt(),
      const UserDiscoveryAnnouncedUsersCompanion(
        isHidden: Value(true),
      ),
    );
  }

  Future<void> _requestUser() async {
    if (_data == null || !_data!.hasAskAboutUserId()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final userId = _data!.askAboutUserId.toInt();
      final userdata = await apiService.getUserById(userId);
      if (userdata != null) {
        await twonlyDB.contactsDao.insertOnConflictUpdate(
          ContactsCompanion(
            username: Value(utf8.decode(userdata.username)),
            userId: Value(userdata.userId.toInt()),
            requested: const Value(false),
            blocked: const Value(false),
            deletedByUser: const Value(false),
          ),
        );
        await importSignalContactAndCreateRequest(userdata);
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
        maxWidth: MediaQuery.of(context).size.width * 0.8,
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
              stream: twonlyDB.contactsDao.watchContact(userId),
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
                stream: twonlyDB.contactsDao.watchContact(userId),
                builder: (context, snapshot) {
                  final contactInDb = snapshot.data;
                  if (contactInDb != null) {
                    return Text(
                      context.lang.chatAskAFriendAddedDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.info.textColor,
                      ),
                    );
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}
