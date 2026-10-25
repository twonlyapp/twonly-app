import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';

class RestoreFlameComp extends StatefulWidget {
  const RestoreFlameComp({
    required this.contactId,
    this.flameOnRightSide = false,
    super.key,
  });
  final int contactId;
  final bool flameOnRightSide;

  @override
  State<RestoreFlameComp> createState() => _RestoreFlameCompState();
}

class _RestoreFlameCompState extends State<RestoreFlameComp> {
  Group? _group;
  bool _canRestore = false;
  bool _restoring = false;
  late String _groupId;
  late StreamSubscription<Group?> _groupSub;

  @override
  void initState() {
    super.initState();
    _groupId = getUUIDforDirectChat(
      widget.contactId,
      userService.currentUser.userId,
    );
    final stream = watchRustDatabase(
      (control) => rust_groups.watchGroups(
        input: db_groups.GroupQuery(
          filter: db_groups.GroupFilter.id,
          groupId: _groupId,
        ),
        control: control,
      ),
    ).map((rows) => rows.isEmpty ? null : rows.single);
    _groupSub = stream.listen((update) async {
      // Whether a restore is still on offer depends on today as much as on the
      // row, so Rust decides it; the row change is only the cue to ask again.
      final canRestore = await rust_groups.canRestoreFlames(groupId: _groupId);
      if (!mounted) return;
      setState(() {
        _group = update;
        _canRestore = canRestore;
      });
    });
  }

  @override
  void dispose() {
    _groupSub.cancel();
    super.dispose();
  }

  Future<void> _restoreFlames() async {
    if (_restoring || _group == null || !_canRestore) return;
    _restoring = true;
    try {
      final currentPlan = planFromString(
        userService.currentUser.subscriptionPlan,
      );
      if (!isUserAllowed(currentPlan, PremiumFeatures.RestoreFlames) &&
          kReleaseMode) {
        await context.push(Routes.settingsSubscription);
        return;
      }
      Log.info(
        'Restoring flames from ${_group!.flameCounter} to ${_group!.maxFlameCounter}',
      );

      // Rust owns the whole restore: the counter, the chat entry, and the forced
      // flame sync that brings the peer back in line.
      final restored = await rust_groups.restoreFlames(groupId: _groupId);
      if (!restored) {
        // The offer may expire or be restored by another tap after it renders.
        Log.warn('Flame restoration is no longer available');
      }
      final canRestore = await rust_groups.canRestoreFlames(groupId: _groupId);
      if (mounted) setState(() => _canRestore = canRestore);
    } finally {
      _restoring = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!userService.currentUser.showRestoreFlame) {
      return const SizedBox.shrink();
    }
    if (_group == null || !_canRestore) {
      return Container();
    }
    if (widget.flameOnRightSide) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: _restoreFlames,
        title: Text(
          context.lang.restoreLostFlames(_group!.maxFlameCounter),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: const SizedBox(
          width: 24,
          child: EmojiAnimationComp(
            emoji: '🔥',
          ),
        ),
      );
    }
    return BetterListTile(
      onTap: _restoreFlames,
      leading: const SizedBox(
        width: 24,
        child: EmojiAnimationComp(
          emoji: '🔥',
        ),
      ),
      text: context.lang.restoreLostFlames(_group!.maxFlameCounter),
    );
  }
}
