import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fixnum/fixnum.dart' show Int64;
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart'
    show IdentityKeyPair;
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pbserver.dart';
import 'package:twonly/src/services/api/messages.api.dart'
    show sendCipherText, tryToSendCompleteMessage;
import 'package:twonly/src/services/group.service.dart' show fetchGroupState;
import 'package:twonly/src/utils/log.dart';

Future<void> handleErrorMessage(
  int fromUserId,
  EncryptedContent_ErrorMessages error,
  String receiptId, {
  String? groupId,
}) async {
  Log.warn('[$receiptId] Got error from $fromUserId: $error');

  switch (error.type) {
    case EncryptedContent_ErrorMessages_Type
        .ERROR_PROCESSING_MESSAGE_CREATED_ACCOUNT_REQUEST_INSTEAD:
      await twonlyDB.receiptsDao.updateReceiptWidthUserId(
        fromUserId,
        error.relatedReceiptId,
        ReceiptsCompanion(markForRetryAfterAccepted: Value(clock.now())),
      );
      await twonlyDB.contactsDao.updateContact(
        fromUserId,
        const ContactsCompanion(
          accepted: Value(false),
          requested: Value(true),
        ),
      );
    case EncryptedContent_ErrorMessages_Type.SESSION_OUT_OF_SYNC:
      break; // The other user initiated a new signal session, so ignore the error in this case, as the new session works...
    case EncryptedContent_ErrorMessages_Type.GROUP_NOT_FOUND_OR_NOT_A_MEMBER:
      if (groupId == null) {
        Log.warn(
          '[$receiptId] GROUP_NOT_FOUND_OR_NOT_A_MEMBER error received, but groupId is null.',
        );
        return;
      }
      final group = await twonlyDB.groupsDao.getGroup(groupId);
      if (group == null) {
        Log.warn(
          '[$receiptId] GROUP_NOT_FOUND_OR_NOT_A_MEMBER error received, but group $groupId is not found in database.',
        );
        return;
      }
      // Update group state from the server to ensure the user is still part of the group...
      final updatedState = await fetchGroupState(group);
      if (updatedState != null) {
        final (_, state) = updatedState;
        final isStillMember = state.memberIds.contains(Int64(fromUserId));
        if (isStillMember) {
          final keyPair = IdentityKeyPair.fromSerialized(
            group.myGroupPrivateKey!,
          );
          await sendCipherText(
            fromUserId,
            EncryptedContent(
              groupId: groupId,
              groupCreate: EncryptedContent_GroupCreate(
                stateKey: group.stateEncryptionKey,
                groupPublicKey: keyPair.getPublicKey().serialize(),
              ),
            ),
          );
        }
        final r = await twonlyDB.receiptsDao.getReceiptById(
          error.relatedReceiptId,
        );
        if (r != null) {
          await twonlyDB.receiptsDao.updateReceiptWidthUserId(
            fromUserId,
            error.relatedReceiptId,
            ReceiptsCompanion(
              markForRetry: Value(clock.now()),
              retryCount: Value(r.retryCount + 1),
            ),
          );
        }
        // then resend: error.relatedReceiptId
        await tryToSendCompleteMessage(
          receiptId: error.relatedReceiptId,
          blocking: false,
        );
      } else {}
    // ignore: no_default_cases
    default:
      break;
  }
}
