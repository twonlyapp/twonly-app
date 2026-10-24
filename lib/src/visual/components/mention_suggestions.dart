import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/mention_editing_controller.dart';
import 'package:twonly/src/visual/components/mention_text.dart';

/// Shared by the chat composer and message editor. Rows contain only the
/// receiver's local display name; membership changes update the choices live.
class MentionSuggestions extends StatefulWidget {
  const MentionSuggestions({
    required this.group,
    required this.controller,
    required this.focusNode,
    super.key,
  });
  final Group group;
  final MentionEditingController controller;
  final FocusNode focusNode;

  @override
  State<MentionSuggestions> createState() => _MentionSuggestionsState();
}

class _MentionSuggestionsState extends State<MentionSuggestions> {
  StreamSubscription<GroupMembersWithContacts>? _subscription;
  Map<int, Contact> _contacts = {};
  Set<int> _activeIds = {};
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    widget.focusNode.addListener(_changed);
    _watch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshNames();
  }

  @override
  void didUpdateWidget(MentionSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_changed);
      widget.focusNode.addListener(_changed);
    }
    if (oldWidget.group.groupId != widget.group.groupId ||
        oldWidget.group.isDirectChat != widget.group.isDirectChat) {
      _watch();
    }
    if (oldWidget.controller != widget.controller) _refreshNames();
  }

  void _watch() {
    final generation = ++_generation;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _contacts = {};
    _activeIds = {};
    // Direct chats can still render/edit an existing token, but offer no picker.
    if (widget.group.isDirectChat) return;
    _subscription =
        watchRustDatabase(
          (control) => rust_groups.watchGroupContacts(
            input: GroupMembersQuery(
              groupId: widget.group.groupId,
              activeOnly: false,
            ),
            control: control,
          ),
        ).listen(
          (rows) {
            if (!mounted || generation != _generation) return;
            _contacts = {
              for (final contact in rows.contacts) contact.userId: contact,
            };
            _activeIds = {
              for (final member in rows.members)
                if (member.memberStateName != 'leftGroup') member.contactId,
            };
            _refreshNames();
            setState(() {});
          },
          onError: (Object error) =>
              Log.warn('Could not load mention suggestions: $error'),
        );
  }

  void _refreshNames() => widget.controller.refreshNames(
    (id) => mentionDisplayName(context, id, _contacts),
  );

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    widget.focusNode.removeListener(_changed);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.controller.mentionQuery;
    if (widget.group.isDirectChat ||
        widget.group.leftGroup ||
        !widget.focusNode.hasFocus ||
        query == null) {
      return const SizedBox.shrink();
    }
    final search = query.query.toLowerCase();
    final contacts =
        _contacts.values
            .where(
              (contact) =>
                  _activeIds.contains(contact.userId) &&
                  (getContactDisplayName(
                        contact,
                      ).toLowerCase().contains(search) ||
                      contact.username.toLowerCase().contains(search)),
            )
            .toList()
          ..sort(
            (a, b) => getContactDisplayName(
              a,
            ).toLowerCase().compareTo(getContactDisplayName(b).toLowerCase()),
          );
    if (contacts.isEmpty) return const SizedBox.shrink();
    return TextFieldTapRegion(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Material(
          color: context.color.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  dense: true,
                  title: Text(getContactDisplayName(contact)),
                  onTap: () {
                    widget.controller.insertMention(
                      contact.userId,
                      getContactDisplayName(contact),
                    );
                    widget.focusNode.requestFocus();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
