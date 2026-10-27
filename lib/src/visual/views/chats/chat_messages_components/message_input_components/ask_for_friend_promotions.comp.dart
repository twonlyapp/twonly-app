import 'dart:async';
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';

class AskForFriendPromotionsComp extends StatefulWidget {
  const AskForFriendPromotionsComp({
    required this.group,
    this.onHighlightChanged,
    super.key,
  });

  final Group group;
  final ValueChanged<bool>? onHighlightChanged;

  @override
  State<AskForFriendPromotionsComp> createState() =>
      _AskForFriendPromotionsCompState();
}

class _AskForFriendPromotionsCompState extends State<AskForFriendPromotionsComp>
    with SingleTickerProviderStateMixin {
  Contact? _contact;
  StreamSubscription<Contact?>? _subscription;
  late final AnimationController _arrowController;
  late final Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();
    _initContactWatcher();

    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _arrowAnimation = Tween<double>(begin: -2, end: 3).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AskForFriendPromotionsComp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.groupId != widget.group.groupId) {
      _initContactWatcher();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _arrowController.dispose();
    // Schedule state callback outside of dispose to avoid setState call during build/dispose issues
    final callback = widget.onHighlightChanged;
    if (callback != null) {
      scheduleMicrotask(() => callback(false));
    }
    super.dispose();
  }

  Future<void> _initContactWatcher() async {
    await _subscription?.cancel();
    if (!widget.group.isDirectChat) {
      setState(() {
        _contact = null;
      });
      widget.onHighlightChanged?.call(false);
      return;
    }

    final members = joinedGroupContacts(
      await watchRustDatabase(
        (control) => rust_groups.watchGroupContacts(
          input: db_groups.GroupMembersQuery(
            groupId: widget.group.groupId,
            orderForChats: true,
          ),
          control: control,
        ),
      ).first,
    ).map((row) => row.$1).toList(growable: false);
    if (!mounted) return;
    if (members.isEmpty) {
      setState(() {
        _contact = null;
      });
      widget.onHighlightChanged?.call(false);
      return;
    }

    final contactId = members.first.userId;
    _subscription =
        watchRustDatabase(
          (control) => rust_contacts.watchContacts(
            input: db_contacts.ContactQuery(
              filter: db_contacts.ContactFilter.ids,
              ids: Int64List.fromList([contactId].toList()),
            ),
            control: control,
          ),
        ).map((rows) => rows.isEmpty ? null : rows.single).listen((
          contact,
        ) {
          if (mounted) {
            setState(() {
              _contact = contact;
            });
            final shouldHighlight = contact?.askForFriendPromotions == true;
            widget.onHighlightChanged?.call(shouldHighlight);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_contact == null || _contact!.askForFriendPromotions != true) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(40),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(60),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              await rust_contacts.updateContact(
                id: _contact!.userId,
                patch: ContactPatch(
                  askForFriendPromotions: NullableInt(
                    value: databaseNullableFlag(false),
                  ),
                ),
                transaction: currentDatabaseSession(),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: FaIcon(
                FontAwesomeIcons.xmark,
                size: 13,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withAlpha(150),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                context.lang.askForFriendPromotionsPrompt(
                  _contact!.displayName ?? _contact!.username,
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: AnimatedBuilder(
              animation: _arrowAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -pi / 10,
                  child: Transform.translate(
                    offset: Offset(0, _arrowAnimation.value),
                    child: child,
                  ),
                );
              },
              child: FaIcon(
                FontAwesomeIcons.anglesDown,
                color: Theme.of(context).colorScheme.primary,
                size: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
