// ignore_for_file: parameter_assignments

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/flame_counter.comp.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/context_menu/user.context_menu.dart';
import 'package:twonly/src/visual/decorations/input_text.decoration.dart';
import 'package:twonly/src/visual/elements/contact_chip.element.dart';

class SelectedContactView {
  const SelectedContactView({
    required this.title,
    required this.submitButton,
    required this.submitIcon,
    this.alreadySelectedSubtitle,
  });
  final String title;
  final String Function(int selected, int? limit) submitButton;
  final FaIconData submitIcon;
  final String? alreadySelectedSubtitle;
}

class SelectContactsView extends StatefulWidget {
  const SelectContactsView({
    required this.text,
    this.alreadySelected,
    this.limit,
    this.isAlreadySelectedLocked = true,
    this.onlyVerified = false,
    this.sortByMediaCount = false,
    super.key,
  });
  final SelectedContactView text;
  final List<int>? alreadySelected;
  final int? limit;
  final bool isAlreadySelectedLocked;
  final bool onlyVerified;
  final bool sortByMediaCount;

  @override
  State<SelectContactsView> createState() => _SelectAdditionalUsers();
}

class _SelectAdditionalUsers extends State<SelectContactsView> {
  List<Contact> contacts = [];
  List<Contact> allContacts = [];
  final TextEditingController searchUserName = TextEditingController();
  late StreamSubscription<List<Contact>> contactSub;

  final HashSet<int> selectedUsers = HashSet();
  late HashSet<int> _alreadySelected;
  final HashSet<int> verifiedUserIds = HashSet();

  @override
  void initState() {
    super.initState();

    _alreadySelected = HashSet.from(widget.alreadySelected ?? []);
    if (!widget.isAlreadySelectedLocked) {
      selectedUsers.addAll(_alreadySelected);
      _alreadySelected.clear();
    }

    final stream = twonlyDB.contactsDao.watchAllAcceptedContacts();

    contactSub = stream.listen((update) async {
      update.sort(
        (a, b) => getContactDisplayName(a).compareTo(getContactDisplayName(b)),
      );
      setState(() {
        allContacts = update;
      });
      await filterUsers();
    });

    _loadVerifiedContacts();
  }

  Future<void> _loadVerifiedContacts() async {
    final kvs = await twonlyDB.select(twonlyDB.keyVerifications).get();
    final urs = await (twonlyDB.select(
      twonlyDB.userDiscoveryUserRelations,
    )..where((u) => u.publicKeyVerifiedTimestamp.isNotNull())).get();

    if (!mounted) return;
    setState(() {
      verifiedUserIds
        ..addAll(kvs.map((row) => row.contactId))
        ..addAll(urs.map((row) => row.announcedUserId));
    });
    await filterUsers();
  }

  @override
  void dispose() {
    unawaited(contactSub.cancel());
    super.dispose();
  }

  Future<void> filterUsers() async {
    var filtered = allContacts;
    if (searchUserName.value.text.isNotEmpty) {
      filtered = filtered
          .where(
            (user) => getContactDisplayName(
              user,
            ).toLowerCase().contains(searchUserName.value.text.toLowerCase()),
          )
          .toList();
    }

    if (widget.sortByMediaCount) {
      filtered.sort((a, b) {
        final aVerified = verifiedUserIds.contains(a.userId);
        final bVerified = verifiedUserIds.contains(b.userId);
        if (aVerified && !bVerified) return -1;
        if (!aVerified && bVerified) return 1;

        final cmp = b.mediaSendCounter.compareTo(a.mediaSendCounter);
        if (cmp != 0) return cmp;

        return getContactDisplayName(a).compareTo(getContactDisplayName(b));
      });
    } else {
      filtered.sort(
        (a, b) => getContactDisplayName(a).compareTo(getContactDisplayName(b)),
      );
    }

    setState(() {
      contacts = filtered;
    });
  }

  void toggleSelectedUser(int userId) {
    if (_alreadySelected.contains(userId)) return;
    if (!selectedUsers.contains(userId)) {
      if (widget.limit == null || selectedUsers.length < widget.limit!) {
        selectedUsers.add(userId);
      }
    } else {
      selectedUsers.remove(userId);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.text.title),
        ),
        floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
        floatingActionButton: FilledButton.icon(
          onPressed: selectedUsers.isEmpty
              ? null
              : () => Navigator.pop(context, selectedUsers.toList()),
          label: Text(
            widget.text.submitButton(
              selectedUsers.length + _alreadySelected.length,
              widget.limit,
            ),
          ),
          icon: FaIcon(widget.text.submitIcon),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 40,
              left: 10,
              top: 20,
              right: 10,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    onChanged: (_) async {
                      await filterUsers();
                    },
                    controller: searchUserName,
                    decoration: getInputDecoration(
                      context,
                      context.lang.shareImageSearchAllContacts,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    restorationId: 'new_message_users_list',
                    itemCount:
                        contacts.length + (selectedUsers.isEmpty ? 0 : 2),
                    itemBuilder: (context, i) {
                      if (selectedUsers.isNotEmpty) {
                        final selected = selectedUsers.toList();
                        if (i == 0) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            constraints: const BoxConstraints(
                              maxHeight: 150,
                            ),
                            child: SingleChildScrollView(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Wrap(
                                    spacing: 8,
                                    children: selected.map((w) {
                                      final contact = allContacts
                                          .where((t) => t.userId == w)
                                          .firstOrNull;
                                      if (contact == null) {
                                        return const SizedBox.shrink();
                                      }
                                      return ContactChip(
                                        key: ValueKey(contact.userId),
                                        contact: contact,
                                        onTap: toggleSelectedUser,
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                        if (i == 1) {
                          return const Divider();
                        }
                        i -= 2;
                      }
                      final user = contacts[i];
                      final isVerified = verifiedUserIds.contains(user.userId);
                      final isSelectionDisabled =
                          widget.onlyVerified && !isVerified;
                      return UserContextMenu(
                        key: ValueKey(user.userId),
                        contact: user,
                        child: ListTile(
                          enabled: !isSelectionDisabled,
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  getContactDisplayName(user),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              VerificationBadgeComp(
                                contact: user,
                                size: 14,
                                clickable: false,
                              ),
                              FlameCounterWidget(
                                contactId: user.userId,
                                prefix: true,
                              ),
                            ],
                          ),
                          subtitle: (_alreadySelected.contains(user.userId))
                              ? (widget.text.alreadySelectedSubtitle != null
                                    ? Text(widget.text.alreadySelectedSubtitle!)
                                    : Text(context.lang.alreadyInGroup))
                              : (isSelectionDisabled
                                    ? Text(
                                        context.lang.contactNotVerified,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                      )
                                    : null),
                          leading: AvatarIcon(
                            contactId: user.userId,
                            fontSize: 13,
                          ),
                          trailing: Checkbox.adaptive(
                            value:
                                selectedUsers.contains(user.userId) |
                                _alreadySelected.contains(user.userId),
                            side: WidgetStateBorderSide.resolveWith(
                              (states) {
                                if (states.contains(WidgetState.selected)) {
                                  return const BorderSide(width: 0);
                                }
                                return BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                );
                              },
                            ),
                            onChanged: isSelectionDisabled
                                ? null
                                : (value) {
                                    toggleSelectedUser(user.userId);
                                  },
                          ),
                          onTap: isSelectionDisabled
                              ? null
                              : () {
                                  toggleSelectedUser(user.userId);
                                },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
