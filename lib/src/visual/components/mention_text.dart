import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/mentions.dart';
import 'package:twonly/src/utils/misc.dart';

String mentionDisplayName(
  BuildContext context,
  int id,
  Map<int, Contact> contacts,
) {
  final contact = contacts[id];
  if (contact != null) return getContactDisplayName(contact);
  if (locator.isRegistered<UserService>() && userService.isUserCreated) {
    final own = userService.currentUser;
    if (own.userId == id) {
      return own.displayName.isEmpty ? own.username : own.displayName;
    }
  }
  return context.lang.chatMentionUnknownUser;
}

/// Resolves only the referenced accounts and refreshes on local contact renames.
class MentionNames extends StatefulWidget {
  const MentionNames({
    required this.text,
    required this.builder,
    this.contactsById,
    super.key,
  });
  final String text;
  final Map<int, Contact>? contactsById;
  final Widget Function(BuildContext, String Function(int)) builder;

  @override
  State<MentionNames> createState() => _MentionNamesState();
}

class _MentionNamesState extends State<MentionNames> {
  StreamSubscription<List<Contact>>? _subscription;
  Map<int, Contact> _contacts = {};
  Set<int> _ids = {};

  @override
  void initState() {
    super.initState();
    _watch();
  }

  @override
  void didUpdateWidget(MentionNames oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        (oldWidget.contactsById == null) != (widget.contactsById == null)) {
      _watch();
    }
  }

  void _watch() {
    if (widget.contactsById != null) {
      unawaited(_subscription?.cancel());
      _subscription = null;
      _ids = {};
      _contacts = {};
      return;
    }
    final ids = parseMentions(
      widget.text,
    ).map((part) => part.userId).nonNulls.toSet();
    if (ids.length == _ids.length && ids.containsAll(_ids)) return;
    _ids = ids;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _contacts = {};
    if (ids.isEmpty) return;
    _subscription =
        watchRustDatabase(
          (control) => rust_contacts.watchContacts(
            input: ContactQuery(
              filter: ContactFilter.ids,
              ids: Int64List.fromList(ids.toList()),
            ),
            control: control,
          ),
        ).listen(
          (contacts) {
            if (!mounted || !identical(_ids, ids)) return;
            setState(
              () => _contacts = {
                for (final contact in contacts) contact.userId: contact,
              },
            );
          },
          onError: (Object error) =>
              Log.warn('Could not resolve mentions: $error'),
        );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    (id) => mentionDisplayName(context, id, widget.contactsById ?? _contacts),
  );
}
