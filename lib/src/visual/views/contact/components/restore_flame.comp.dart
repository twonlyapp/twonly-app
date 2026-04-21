import 'dart:async';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/services/api/messages.api.dart';
import 'package:twonly/src/services/flame.service.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';

class RestoreFlameComp extends StatefulWidget {
  const RestoreFlameComp({
    required this.contactId,
    super.key,
  });
  final int contactId;

  @override
  State<RestoreFlameComp> createState() => _RestoreFlameCompState();
}

class _RestoreFlameCompState extends State<RestoreFlameComp> {
  Group? _group;
  late String _groupId;
  late StreamSubscription<Group?> _groupSub;

  @override
  void initState() {
    _groupId = getUUIDforDirectChat(
      widget.contactId,
      appSession.currentUser.userId,
    );
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
    final currentPlan = planFromString(appSession.currentUser.subscriptionPlan);
    if (!isUserAllowed(currentPlan, PremiumFeatures.RestoreFlames) &&
        kReleaseMode) {
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

    final addData = AdditionalMessageData(
      type: AdditionalMessageData_Type.RESTORED_FLAME_COUNTER,
      restoredFlameCounter: Int64(_group!.maxFlameCounter),
    );

    final message = await twonlyDB.messagesDao.insertMessage(
      MessagesCompanion(
        groupId: Value(_groupId),
        type: Value(MessageType.restoreFlameCounter.name),
        additionalMessageData: Value(addData.writeToBuffer()),
      ),
    );

    if (message == null) {
      Log.error('Could not insert message into database');
      return;
    }

    final encryptedContent = pb.EncryptedContent(
      additionalDataMessage: pb.EncryptedContent_AdditionalDataMessage(
        senderMessageId: message.messageId,
        additionalMessageData: addData.writeToBuffer(),
        timestamp: Int64(message.createdAt.millisecondsSinceEpoch),
        type: MessageType.restoreFlameCounter.name,
      ),
    );

    await syncFlameCounters(forceForGroup: _groupId);
    await sendCipherTextToGroup(
      _groupId,
      encryptedContent,
      messageId: message.messageId,
    );
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
        child: EmojiAnimationComp(
          emoji: '🔥',
        ),
      ),
      text: 'Restore your ${_group!.maxFlameCounter} lost flames',
    );
  }
}
