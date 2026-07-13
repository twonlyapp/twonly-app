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
import 'package:twonly/src/visual/context_menu/user.context_menu.dart';
import 'package:twonly/src/visual/decorations/input_text.decoration.dart';
import 'package:twonly/src/visual/elements/contact_chip.element.dart';

class SelectAdditionalUsers extends StatefulWidget {
  const SelectAdditionalUsers({
    required this.alreadySelected,
    required this.limit,
    super.key,
  });
  final List<int> alreadySelected;
  final int limit;
  @override
  State<SelectAdditionalUsers> createState() => _SelectAdditionalUsers();
}

class _SelectAdditionalUsers extends State<SelectAdditionalUsers> {
  List<Contact> contacts = [];
  List<Contact> allContacts = [];
  final TextEditingController searchUserName = TextEditingController();
  late StreamSubscription<List<Contact>> contactSub;

  final HashSet<int> selectedUsers = HashSet();
  late HashSet<int> _alreadySelected;

  @override
  void initState() {
    super.initState();

    _alreadySelected = HashSet.from(widget.alreadySelected);

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
  }

  @override
  void dispose() {
    unawaited(contactSub.cancel());
    super.dispose();
  }

  Future<void> filterUsers() async {
    if (searchUserName.value.text.isEmpty) {
      setState(() {
        contacts = allContacts;
      });
      return;
    }
    final usersFiltered = allContacts
        .where(
          (user) => getContactDisplayName(
            user,
          ).toLowerCase().contains(searchUserName.value.text.toLowerCase()),
        )
        .toList();
    setState(() {
      contacts = usersFiltered;
    });
  }

  void toggleSelectedUser(int userId) {
    if (_alreadySelected.contains(userId)) return;
    if (!selectedUsers.contains(userId)) {
      if (selectedUsers.length < widget.limit) {
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
          title: Text(context.lang.additionalUserSelectTitle),
        ),
        floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
        floatingActionButton: FilledButton.icon(
          onPressed: selectedUsers.isEmpty
              ? null
              : () => Navigator.pop(context, selectedUsers.toList()),
          label: Text(
            context.lang.additionalUserSelectButton(
              widget.limit,
              selectedUsers.length + widget.alreadySelected.length,
            ),
          ),
          icon: const FaIcon(FontAwesomeIcons.userPlus),
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
                                      final contact = allContacts.firstWhere(
                                        (t) => t.userId == w,
                                      );
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
                      return UserContextMenu(
                        key: ValueKey(user.userId),
                        contact: user,
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(getContactDisplayName(user)),
                              FlameCounterWidget(
                                contactId: user.userId,
                                prefix: true,
                              ),
                            ],
                          ),
                          subtitle: (_alreadySelected.contains(user.userId))
                              ? Text(context.lang.alreadyInGroup)
                              : null,
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
                            onChanged: (value) {
                              toggleSelectedUser(user.userId);
                            },
                          ),
                          onTap: () {
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
