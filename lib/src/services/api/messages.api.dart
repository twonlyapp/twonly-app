import 'dart:typed_data';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    as frb;
import 'package:twonly/core/bridge/api.dart' as rust_api;
import 'package:twonly/src/database/twonly.db.dart' show Receipt;
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;

Future<(Uint8List, Uint8List?)?> tryToSendCompleteMessage({
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
  final prepared = await rust_api.RustApi.prepareQueuedMessage(receiptId: id);
  return prepared == null ? null : (prepared.message, prepared.pushData);
}

Future<void> insertAndSendTextMessage(
  String groupId,
  String textMessage,
  String? quotesMessageId,
) async {
  await rust_api.RustApi.insertAndSendText(
    groupId: groupId,
    text: textMessage,
    quoteMessageId: quotesMessageId,
  );
}

Future<void> insertAndSendContactShareMessage(
  String groupId,
  List<int> contactsToShare,
) async {
  await rust_api.RustApi.insertAndSendContactShare(
    groupId: groupId,
    contactIds: frb.Int64List.fromList(contactsToShare),
  );
}

Future<void> insertAndSendAskAboutUserMessage(
  int contactId,
  int askAboutUserId,
) async {
  await rust_api.RustApi.insertAndSendAskAboutUser(
    contactId: contactId,
    askAboutUserId: askAboutUserId,
  );
}

Future<void> sendCipherTextToGroup(
  String groupId,
  pb.EncryptedContent encryptedContent, {
  String? messageId,
  bool onlySendIfNoReceiptsAreOpen = false,
}) async {
  await rust_api.RustApi.sendEncryptedContentToGroup(
    groupId: groupId,
    content: encryptedContent.writeToBuffer(),
    messageId: messageId,
    onlySendIfNoReceiptsAreOpen: onlySendIfNoReceiptsAreOpen,
  );
}

Future<(Uint8List, Uint8List?)?> sendCipherText(
  int contactId,
  pb.EncryptedContent encryptedContent, {
  bool onlyReturnEncryptedData = false,
  bool blocking = true,
  String? messageId,
  bool onlySendIfNoReceiptsAreOpen = false,
}) async {
  final prepared = await rust_api.RustApi.sendEncryptedContent(
    contactId: contactId,
    content: encryptedContent.writeToBuffer(),
    messageId: messageId,
    onlySendIfNoReceiptsAreOpen: onlySendIfNoReceiptsAreOpen,
    onlyReturnEncryptedData: onlyReturnEncryptedData,
    blocking: blocking,
  );
  if (!onlyReturnEncryptedData || prepared == null) return null;
  return (prepared.message, prepared.pushData);
}

Future<void> sendTypingIndication(String groupId, bool isTyping) =>
    rust_api.RustApi.sendTyping(groupId: groupId, isTyping: isTyping);

Future<void> notifyContactAboutOpeningMessage(
  int contactId,
  List<String> messageOtherIds,
) => rust_api.RustApi.notifyMessagesOpened(
  contactId: contactId,
  messageIds: messageOtherIds,
);

Future<void> sendContactMyProfileData(int contactId) =>
    rust_api.RustApi.sendContactProfile(contactId: contactId);
