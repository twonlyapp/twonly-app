import 'dart:async';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/flame.service.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/animate_icon.dart';
import 'package:twonly/src/views/components/better_list_title.dart';

class MaxFlameListTitle extends StatefulWidget {
  const MaxFlameListTitle({
    required this.contactId,
    super.key,
  });
  final int contactId;

  @override
  State<MaxFlameListTitle> createState() => _MaxFlameListTitleState();
}

class _MaxFlameListTitleState extends State<MaxFlameListTitle> {
  Group? _group;
  late String _groupId;
  late StreamSubscription<Group?> _groupSub;

  @override
  void initState() {
    _groupId = getUUIDforDirectChat(widget.contactId, gUser.userId);
    final stream = twonlyDB.groupsDao.watchGroup(_groupId);
    _groupSub = stream.listen((update) {
      if (mounted) setState(() => _group = update);
    });
    super.initState();
  }

  @override
  void dispose() {
    _groupSub.cancel();
    super.dispose();
  }

  Future<void> _restoreFlames() async {
    if (!isUserAllowed(getCurrentPlan(), PremiumFeatures.RestoreFlames)) {
      await context.push(Routes.settingsSubscription);
      return;
    }
    Log.info(
      'Restoring flames from ${_group!.flameCounter} to ${_group!.maxFlameCounter}',
    );
    await twonlyDB.groupsDao.updateGroup(
      _groupId,
      GroupsCompanion(
        flameCounter: Value(_group!.maxFlameCounter),
        lastFlameCounterChange: Value(clock.now()),
      ),
    );
    await syncFlameCounters(forceForGroup: _groupId);
  }

  @override
  Widget build(BuildContext context) {
    if (_group == null || !isItPossibleToRestoreFlames(_group!)) {
      return Container();
    }
    return BetterListTile(
      onTap: _restoreFlames,
      leading: const SizedBox(
        width: 24,
        child: EmojiAnimation(
          emoji: '🔥',
        ),
      ),
      text: 'Restore your ${_group!.maxFlameCounter} lost flames',
    );
  }
}
