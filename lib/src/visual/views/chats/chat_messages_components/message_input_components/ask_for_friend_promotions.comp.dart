import 'dart:async';
import 'dart:math' show pi;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
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

    final members = await twonlyDB.groupsDao.getGroupContact(
      widget.group.groupId,
    );
    if (members.isEmpty) {
      setState(() {
        _contact = null;
      });
      widget.onHighlightChanged?.call(false);
      return;
    }

    final contactId = members.first.userId;
    _subscription = twonlyDB.contactsDao.watchContact(contactId).listen((
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
              await twonlyDB.contactsDao.updateContact(
                _contact!.userId,
                const ContactsCompanion(
                  askForFriendPromotions: Value(false),
                ),
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
