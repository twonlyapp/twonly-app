import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';

const noContactGroupBackgroundColor = 0x00000000;

bool contactGroupHasBackground(int backgroundColor) =>
    backgroundColor & 0xFF000000 != noContactGroupBackgroundColor;

double contactGroupFontSize(double baseFontSize, int backgroundColor) =>
    contactGroupHasBackground(backgroundColor)
    ? baseFontSize
    : baseFontSize * 1.5;

class ContactGroupBadges extends StatefulWidget {
  const ContactGroupBadges({
    this.userId,
    this.groupId,
    this.fontSize = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.emptyText,
    this.showEmptyText = false,
    this.contactGroups,
    super.key,
  }) : assert(
         userId != null || groupId != null || contactGroups != null,
         'pass a userId, a groupId or the contact groups themselves',
       );

  final int? userId;
  final String? groupId;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final String? emptyText;
  final bool showEmptyText;
  final List<ContactGroup>? contactGroups;

  @override
  State<ContactGroupBadges> createState() => _ContactGroupBadgesState();
}

class _ContactGroupBadgesState extends State<ContactGroupBadges> {
  List<ContactGroup> _contactGroups = [];
  StreamSubscription<List<ContactGroup>>? _subscription;

  @override
  void initState() {
    super.initState();
    if (widget.contactGroups != null) {
      _contactGroups = widget.contactGroups!;
    } else {
      final groupId = widget.groupId;
      _subscription =
          (groupId != null
                  ? twonlyDB.contactGroupsDao.watchVisibleGroupsForGroup(
                      groupId,
                    )
                  : twonlyDB.contactGroupsDao.watchVisibleGroupsForUser(
                      widget.userId!,
                    ))
              .listen((contactGroups) {
                if (mounted) setState(() => _contactGroups = contactGroups);
              });
    }
  }

  @override
  void didUpdateWidget(ContactGroupBadges oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contactGroups != null &&
        widget.contactGroups != oldWidget.contactGroups) {
      _contactGroups = widget.contactGroups!;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_contactGroups.isEmpty) {
      if (!widget.showEmptyText && widget.emptyText == null) {
        return const SizedBox.shrink();
      }
      return Text(
        widget.emptyText ?? context.lang.contactGroupsSubtitleEmpty,
        style: TextStyle(
          fontSize: widget.fontSize,
          color: Theme.of(context).disabledColor,
        ),
      );
    }

    return _BadgeMarquee(
      children: _contactGroups.map((contactGroup) {
        final hasBackground = contactGroupHasBackground(
          contactGroup.backgroundColor,
        );
        return Container(
          padding: hasBackground ? widget.padding : EdgeInsets.zero,
          decoration: hasBackground
              ? BoxDecoration(
                  color: Color(contactGroup.backgroundColor),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Text(
            contactGroup.name,
            style: TextStyle(
              fontSize: contactGroupFontSize(
                widget.fontSize,
                contactGroup.backgroundColor,
              ),
              color: Color(contactGroup.textColor),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Lays the badges out on a single line. When they do not fit the available
/// width they slowly scroll from right to left instead of wrapping or
/// overflowing.
class _BadgeMarquee extends StatefulWidget {
  const _BadgeMarquee({required this.children});

  final List<Widget> children;

  @override
  State<_BadgeMarquee> createState() => _BadgeMarqueeState();
}

class _BadgeMarqueeState extends State<_BadgeMarquee> {
  /// Logical pixels per second the badges travel.
  static const _speed = 15.0;
  static const _pause = Duration(milliseconds: 1500);

  final ScrollController _controller = ScrollController();
  bool _scrolling = false;

  @override
  void initState() {
    super.initState();
    _scheduleScroll();
  }

  @override
  void didUpdateWidget(_BadgeMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) {
      _scheduleScroll();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scheduleScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_scroll()));
  }

  Future<void> _scroll() async {
    if (_scrolling) return;
    _scrolling = true;
    try {
      while (mounted && _controller.hasClients) {
        final distance = _controller.position.maxScrollExtent;
        if (distance <= 0) return;
        final duration = Duration(
          milliseconds: (distance / _speed * 1000).round(),
        );
        if (!await _wait(_pause)) return;
        await _controller.animateTo(
          distance,
          duration: duration,
          curve: Curves.linear,
        );
        if (!await _wait(_pause)) return;
        if (!mounted || !_controller.hasClients) return;
        await _controller.animateTo(
          0,
          duration: duration,
          curve: Curves.linear,
        );
      }
    } finally {
      _scrolling = false;
    }
  }

  /// Waits and reports whether the marquee may keep running afterwards.
  Future<bool> _wait(Duration duration) async {
    await Future<void>.delayed(duration);
    return mounted && _controller.hasClients;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.children.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            widget.children[i],
          ],
        ],
      ),
    );
  }
}

class ContactGroupsSubtitleBuilder extends StatelessWidget {
  const ContactGroupsSubtitleBuilder({
    required this.builder,
    this.userId,
    this.groupId,
    this.additionalSubtitle,
    super.key,
  }) : assert(
         userId != null || groupId != null,
         'pass either a userId or a groupId',
       );

  final int? userId;
  final String? groupId;
  final Widget? additionalSubtitle;
  final Widget Function(BuildContext context, Widget? subtitleWidget) builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ContactGroup>>(
      stream: groupId != null
          ? twonlyDB.contactGroupsDao.watchVisibleGroupsForGroup(groupId!)
          : twonlyDB.contactGroupsDao.watchVisibleGroupsForUser(userId!),
      builder: (context, snapshot) {
        final contactGroups = snapshot.data ?? const [];
        Widget? subtitle;
        if (additionalSubtitle != null) {
          subtitle = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              additionalSubtitle!,
              if (contactGroups.isNotEmpty)
                ContactGroupBadges(
                  userId: userId,
                  groupId: groupId,
                  contactGroups: contactGroups,
                ),
            ],
          );
        } else if (contactGroups.isNotEmpty) {
          subtitle = ContactGroupBadges(
            userId: userId,
            groupId: groupId,
            contactGroups: contactGroups,
          );
        }
        return builder(context, subtitle);
      },
    );
  }
}
