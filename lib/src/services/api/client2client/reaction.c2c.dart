import 'package:clock/clock.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/mediafiles/upload.api.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> handleReaction(
  int fromUserId,
  String groupId,
  EncryptedContent_Reaction reaction,
) async {
  Log.info('Got a reaction from $fromUserId (remove=${reaction.remove})');
  await twonlyDB.reactionsDao.updateReaction(
    fromUserId,
    reaction.targetMessageId,
    groupId,
    reaction.emoji,
    reaction.remove,
  );

  await handleMediaRelatedResponseFromReceiver(reaction.targetMessageId);

  if (!reaction.remove) {
    await twonlyDB.groupsDao.increaseLastMessageExchange(groupId, clock.now());
  }
}
