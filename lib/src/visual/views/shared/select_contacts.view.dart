// ignore_for_file: parameter_assignments

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/recovery.dart' as rust_recovery;
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/flame_counter.comp.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/context_menu/user.context_menu.dart';
import 'package:twonly/src/visual/elements/contact_chip.element.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';

/// An optional chat group or contact supplied by a caller with its own live list.
class ContactPickerEntry {
  const ContactPickerEntry({
    required this.name,
    required this.messageCount,
    this.contact,
    this.group,
    this.memberNames = const [],
  }) : assert(
         (contact == null) != (group == null),
         'Provide either a contact or a chat group',
       );

  final String name;
  final int messageCount;
  final Contact? contact;
  final Group? group;
  final List<String> memberNames;
}

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
    this.members,
    this.alreadySelectedGroupIds = const [],
    this.allowEmptySelection = false,
    this.onSubmit,
    super.key,
  });
  final SelectedContactView text;
  final List<int>? alreadySelected;
  final int? limit;
  final bool isAlreadySelectedLocked;
  final bool onlyVerified;
  final bool sortByMediaCount;

  /// Overrides the accepted-contact list, preserving the supplied order.
  final ValueListenable<List<ContactPickerEntry>>? members;
  final List<String> alreadySelectedGroupIds;
  final bool allowEmptySelection;
  final void Function(List<int> userIds, List<String> groupIds)? onSubmit;

  @override
  State<SelectContactsView> createState() => _SelectAdditionalUsers();
}

class _SelectAdditionalUsers extends State<SelectContactsView> {
  List<Contact> contacts = [];
  List<Contact> allContacts = [];
  final TextEditingController searchUserName = TextEditingController();
  StreamSubscription<List<Contact>>? contactSub;
  final Set<String> _selectedGroupIds = {};

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

    _selectedGroupIds.addAll(widget.alreadySelectedGroupIds);
    if (widget.members != null) {
      widget.members!.addListener(_updateMembers);
      _updateMembers();
      unawaited(_loadVerifiedContacts());
      return;
    }

    final stream = watchRustDatabase(
      (control) => rust_contacts.watchContacts(
        input: db_contacts.ContactQuery(
          filter: db_contacts.ContactFilter.accepted,
          ids: Int64List(0),
        ),
        control: control,
      ),
    );

    contactSub = stream.listen((update) async {
      if (!mounted) return;
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
    final ids = (await rust_recovery.verifiedContactIds(
      transaction: currentDatabaseSession(),
    )).map((id) => id.toInt()).toList();
    if (!mounted) return;
    setState(() {
      verifiedUserIds
        ..clear()
        ..addAll(ids);
    });
    await filterUsers();
  }

  @override
  void dispose() {
    unawaited(contactSub?.cancel());
    widget.members?.removeListener(_updateMembers);
    searchUserName.dispose();
    super.dispose();
  }

  void _updateMembers() {
    allContacts = [
      for (final entry in widget.members!.value)
        if (entry.contact != null) entry.contact!,
    ];
    unawaited(filterUsers());
  }

  List<ContactPickerEntry>? get _memberEntries {
    final filter = searchUserName.text.trim().toLowerCase();
    return widget.members?.value
        .where((entry) => entry.name.toLowerCase().contains(filter))
        .toList();
  }

  void _toggleGroup(String id) {
    setState(() {
      if (!_selectedGroupIds.add(id)) _selectedGroupIds.remove(id);
    });
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

    if (widget.members == null && widget.sortByMediaCount) {
      filtered.sort((a, b) {
        final aVerified = verifiedUserIds.contains(a.userId);
        final bVerified = verifiedUserIds.contains(b.userId);
        if (aVerified && !bVerified) return -1;
        if (!aVerified && bVerified) return 1;

        final cmp = b.mediaSendCounter.compareTo(a.mediaSendCounter);
        if (cmp != 0) return cmp;

        return getContactDisplayName(a).compareTo(getContactDisplayName(b));
      });
    } else if (widget.members == null) {
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
    final entries = _memberEntries;
    final selectedCount = selectedUsers.length + _selectedGroupIds.length;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.text.title),
        ),
        floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
        floatingActionButton: MyButton(
          variant: MyButtonVariant.primaryMiddle,
          onPressed: selectedCount == 0 && !widget.allowEmptySelection
              ? null
              : () {
                  final onSubmit = widget.onSubmit;
                  if (onSubmit != null) {
                    onSubmit(
                      selectedUsers.toList(),
                      _selectedGroupIds.toList(),
                    );
                  } else {
                    Navigator.pop(context, selectedUsers.toList());
                  }
                },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(widget.text.submitIcon, size: 16),
              const SizedBox(width: 8),
              Text(
                widget.text.submitButton(
                  selectedCount + _alreadySelected.length,
                  widget.limit,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          // The list runs to the screen edge and scrolls out from under the
          // submit button instead of stopping short above it.
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 10,
              top: 20,
              right: 10,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: MyInput(
                    controller: searchUserName,
                    dense: true,
                    fontWeight: FontWeight.normal,
                    hintText: context.lang.shareImageSearchAllContacts,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    onChanged: (_) => unawaited(filterUsers()),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    restorationId: 'new_message_users_list',
                    padding: EdgeInsets.only(
                      bottom: 100 + MediaQuery.paddingOf(context).bottom,
                    ),
                    itemCount:
                        (entries?.length ?? contacts.length) +
                        (selectedCount == 0 ? 0 : 2),
                    itemBuilder: (context, i) {
                      if (selectedCount > 0) {
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
                                    children: [
                                      ...selected.map((w) {
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
                                      }),
                                      for (final entry
                                          in widget.members?.value ??
                                              const <ContactPickerEntry>[])
                                        if (entry.group != null &&
                                            _selectedGroupIds.contains(
                                              entry.group!.groupId,
                                            ))
                                          InputChip(
                                            key: ValueKey(entry.group!.groupId),
                                            avatar: AvatarIcon(
                                              group: entry.group,
                                              fontSize: 10,
                                            ),
                                            label: Text(entry.name),
                                            onDeleted: () => _toggleGroup(
                                              entry.group!.groupId,
                                            ),
                                          ),
                                    ],
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
                      final entry = entries?[i];
                      if (entry?.group != null) return _groupTile(entry!);
                      final user = entry?.contact ?? contacts[i];
                      final isVerified = verifiedUserIds.contains(user.userId);
                      final isSelectionDisabled =
                          widget.onlyVerified && !isVerified;
                      return UserContextMenu(
                        key: ValueKey(user.userId),
                        contact: user,
                        child: ListTile(
                          key: ValueKey('contact:${user.userId}'),
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

  Widget _groupTile(ContactPickerEntry entry) {
    final group = entry.group!;
    return ListTile(
      key: ValueKey('group:${group.groupId}'),
      leading: AvatarIcon(group: group, fontSize: 13),
      title: Row(
        children: [
          Flexible(child: Text(entry.name, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          VerificationBadgeComp(
            group: group,
            showOnlyIfVerified: true,
            clickable: false,
            size: 12,
          ),
        ],
      ),
      subtitle: entry.memberNames.isEmpty
          ? null
          : Text(
              entry.memberNames.join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: Checkbox.adaptive(
        value: _selectedGroupIds.contains(group.groupId),
        onChanged: (_) => _toggleGroup(group.groupId),
      ),
      onTap: () => _toggleGroup(group.groupId),
    );
  }
}
