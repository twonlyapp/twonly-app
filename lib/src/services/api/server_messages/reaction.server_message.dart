import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> handleReaction(
  int fromUserId,
  String groupId,
  EncryptedContent_Reaction reaction,
) async {
  Log.info('Got a reaction from $fromUserId');
  if (reaction.hasRemove()) {
    if (reaction.remove) {
      await twonlyDB.reactionsDao
          .updateReaction(fromUserId, reaction.targetMessageId, groupId, null);
      return;
    }
  }
  if (reaction.hasEmoji()) {
    await twonlyDB.reactionsDao.updateReaction(
      fromUserId,
      reaction.targetMessageId,
      groupId,
      reaction.emoji,
    );
    await twonlyDB.groupsDao
        .increaseLastMessageExchange(groupId, DateTime.now());
  }
}
