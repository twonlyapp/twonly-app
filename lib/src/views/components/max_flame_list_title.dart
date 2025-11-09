import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/flame.service.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/animate_icon.dart';
import 'package:twonly/src/views/components/better_list_title.dart';
import 'package:twonly/src/views/settings/subscription/subscription.view.dart';

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
  int _flameCounter = 0;
  Group? _directChat;
  late String _groupId;

  late StreamSubscription<int> _flameCounterSub;
  late StreamSubscription<Group?> _groupSub;

  @override
  void initState() {
    _groupId = getUUIDforDirectChat(widget.contactId, gUser.userId);
    final stream = twonlyDB.groupsDao.watchFlameCounter(_groupId);
    _flameCounterSub = stream.listen((counter) {
      if (mounted) {
        setState(() {
          // in the watchFlameCounter a one is added, so remove this here
          _flameCounter = counter - 1;
        });
      }
    });
    final stream2 = twonlyDB.groupsDao.watchGroup(_groupId);
    _groupSub = stream2.listen((update) {
      if (mounted) {
        setState(() {
          _directChat = update;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _flameCounterSub.cancel();
    _groupSub.cancel();
    super.dispose();
  }

  Future<void> _restoreFlames() async {
    if (!isPayingUser(getCurrentPlan())) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return const SubscriptionView();
          },
        ),
      );
      return;
    }
    await twonlyDB.groupsDao.updateGroup(
      _groupId,
      GroupsCompanion(
        flameCounter: Value(_directChat!.maxFlameCounter),
        lastFlameCounterChange: Value(DateTime.now()),
      ),
    );
    await syncFlameCounters(forceForGroup: _groupId);
  }

  @override
  Widget build(BuildContext context) {
    if (_directChat == null ||
        _directChat!.maxFlameCounter <= 2 ||
        _flameCounter >= _directChat!.maxFlameCounter ||
        _directChat!.maxFlameCounterFrom!
            .isBefore(DateTime.now().subtract(const Duration(days: 4)))) {
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
      text: 'Restore your ${_directChat!.maxFlameCounter + 1} lost flames',
    );
  }
}
