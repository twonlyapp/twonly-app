import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pbserver.dart';

Future<void> handleErrorMessage(
  int fromUserId,
  EncryptedContent_ErrorMessages error,
) async {
  switch (error.type) {
    case EncryptedContent_ErrorMessages_Type.UNKNOWN_MESSAGE_TYPE:
      break;
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
  }
}
