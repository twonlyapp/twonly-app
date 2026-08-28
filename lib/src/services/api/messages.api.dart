import 'dart:typed_data';

import 'package:twonly/core/bridge/api.dart' as rust_api;
import 'package:twonly/src/database/twonly.db.dart' show Receipt;

Future<Uint8List?> tryToSendCompleteMessage({
  String? receiptId,
  Receipt? receipt,
  bool onlyReturnEncryptedData = false,
  bool blocking = true,
}) async {
  final id = receiptId ?? receipt?.receiptId;
  if (id == null) return null;
  if (!onlyReturnEncryptedData) {
    await rust_api.RustApi.sendQueuedMessage(receiptId: id);
    return null;
  }
  return rust_api.RustApi.prepareQueuedMessage(receiptId: id);
}
