// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:fixnum/fixnum.dart';
import 'package:twonly/src/constants/secure_storage.keys.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/userdata.model.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart' as pb;
import 'package:twonly/src/model/protobuf/client/generated/push_notification.pb.dart';
import 'package:twonly/src/services/api.service.dart';
import 'package:twonly/src/services/api/messages.api.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/pow.dart';

import 'user_environment.dart';

class RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) {
        return true;
      };
  }
}

class TestClient {
  TestClient(this.localIdSeed) {
    final timeStr = DateTime.now().millisecondsSinceEpoch.toString();
    username = 't_${timeStr.substring(timeStr.length - 6)}$localIdSeed';
  }
  late final UserEnvironment env;
  late final ApiService api;
  final int localIdSeed;
  late String username;
  Group? defaultGroup;
  int realUserId = 0;

  Future<void> init() async {
    env = await UserEnvironment.create(localIdSeed, username);
    api = ApiService();

    await run(() async {
      await createIfNotExistsSignalIdentity();

      Log.info('Connecting to API...');
      final connected = await api.connect();
      Log.info('Connected: $connected');
      if (!connected) throw Exception('Failed to connect to API');

      Log.info('Requesting POW...');
      final powRes = await api.getProofOfWork();
      Log.info('POW result: $powRes');
      if (powRes.$1 == null) throw Exception('Failed to get POW');

      final prefix = powRes.$1!.prefix;
      final difficulty = powRes.$1!.difficulty.toInt();
      final proof = await calculatePoW(prefix, difficulty);

      final regRes = await api.register(username, '', proof);
      if (regRes.isError) {
        throw Exception('Registration failed: ${regRes.error}');
      }

      realUserId = regRes.value.userid.toInt() as int;

      final userData = UserData(
        userId: realUserId,
        username: username,
        displayName: username,
        subscriptionPlan: 'Free',
        currentSetupPage: null,
      );
      // ignore: cascade_invocations
      userData.appVersion = 100;
      await UserService.save(userData);

      await api.authenticate();
      await signalGetPreKeys();
    });
  }

  Future<void> initContact(TestClient other) async {
    await run(() async {
      await env.db.contactsDao.insertContact(
        ContactsCompanion.insert(
          userId: Value(other.realUserId),
          username: other.username,
          accepted: const Value(true),
        ),
      );
      defaultGroup = await env.db.groupsDao.createNewDirectChat(
        other.realUserId,
        GroupsCompanion(groupName: Value(other.username)),
      );

      final dummyPushKeys = [
        PushUser()
          ..userId = Int64(other.realUserId)
          ..pushKeys.add(
            PushKey()
              ..key = Uint8List(32)
              ..id = Int64(12345)
              ..createdAtUnixTimestamp = Int64(
                DateTime.now().millisecondsSinceEpoch,
              ),
          ),
        PushUser()
          ..userId = Int64(realUserId)
          ..pushKeys.add(
            PushKey()
              ..key = Uint8List(32)
              ..id = Int64(67890)
              ..createdAtUnixTimestamp = Int64(
                DateTime.now().millisecondsSinceEpoch,
              ),
          ),
      ];
      await setPushKeys(SecureStorageKeys.sendingPushKeys, dummyPushKeys);
      await setPushKeys(SecureStorageKeys.receivingPushKeys, dummyPushKeys);

      final userData = await api.getUserById(other.realUserId);
      final sessionStarted = await processSignalUserData(userData!);
      if (!sessionStarted) throw Exception('Failed to start session');
    });
  }

  Future<T> run<T>(Future<T> Function() computation) {
    return runInZone(env, api, computation);
  }

  Future<Message> sendText(TestClient target, String text) async {
    return run(() async {
      final m = await env.db.messagesDao.insertMessage(
        MessagesCompanion(
          groupId: Value(defaultGroup!.groupId),
          content: Value(text),
          type: Value(MessageType.text.name),
        ),
      );
      await sendCipherText(
        target.realUserId,
        pb.EncryptedContent(
          groupId: defaultGroup!.groupId,
          textMessage: pb.EncryptedContent_TextMessage()
            ..senderMessageId = m!.messageId
            ..text = text,
        ),
        messageId: m.messageId,
      );
      return m;
    });
  }

  Future<void> sendEncryptedContent(
    TestClient target,
    pb.EncryptedContent content,
  ) async {
    await run(() async {
      await sendCipherText(target.realUserId, content);
    });
  }

  Future<void> sendGroupJoin(
    TestClient target,
    String groupId,
    List<int> groupPublicKey,
  ) async {
    final content = pb.EncryptedContent()
      ..groupId = groupId
      ..groupJoin = (pb.EncryptedContent_GroupJoin()
        ..groupPublicKey = groupPublicKey);
    await sendEncryptedContent(target, content);
  }

  Future<void> sendResendGroupPublicKey(
    TestClient target,
    String groupId,
  ) async {
    final content = pb.EncryptedContent()
      ..groupId = groupId
      ..resendGroupPublicKey = pb.EncryptedContent_ResendGroupPublicKey();
    await sendEncryptedContent(target, content);
  }

  Future<void> sendErrorMessages(
    TestClient target,
    pb.EncryptedContent_ErrorMessages_Type type,
    String receiptId,
  ) async {
    final content = pb.EncryptedContent()
      ..errorMessages = (pb.EncryptedContent_ErrorMessages()
        ..type = type
        ..relatedReceiptId = receiptId);
    await sendEncryptedContent(target, content);
  }

  Future<void> sendUserDiscoveryRequest(
    TestClient target,
    List<int> version,
  ) async {
    final content = pb.EncryptedContent()
      ..userDiscoveryRequest = (pb.EncryptedContent_UserDiscoveryRequest()
        ..currentVersion = version);
    await sendEncryptedContent(target, content);
  }

  Future<void> sendUserDiscoveryUpdate(
    TestClient target,
    List<List<int>> messages,
  ) async {
    final content = pb.EncryptedContent()
      ..userDiscoveryUpdate = (pb.EncryptedContent_UserDiscoveryUpdate()
        ..messages.addAll(messages));
    await sendEncryptedContent(target, content);
  }

  Future<void> sendKeyVerificationProof(
    TestClient target,
    List<int> mac,
  ) async {
    final content = pb.EncryptedContent()
      ..keyVerificationProof = (pb.EncryptedContent_KeyVerificationProof()
        ..calculatedMac = mac);
    await sendEncryptedContent(target, content);
  }

  Future<void> sendDeliveryReceipt(TestClient target, String receiptId) async {
    final msg = pb.Message()
      ..type = pb.Message_Type.SENDER_DELIVERY_RECEIPT
      ..receiptId = receiptId;
    await api.sendTextMessage(target.realUserId, msg.writeToBuffer(), null);
  }

  Future<void> sendReaction(TestClient target, String targetMessageId, String emoji, {bool remove = false}) async {
    final content = pb.EncryptedContent()
      ..groupId = defaultGroup!.groupId
      ..reaction = (pb.EncryptedContent_Reaction()
        ..targetMessageId = targetMessageId
        ..emoji = emoji
        ..remove = remove);
    await sendEncryptedContent(target, content);
  }

  Future<void> sendMessageUpdate(TestClient target, String targetMessageId, pb.EncryptedContent_MessageUpdate_Type type, {String? text}) async {
    final update = pb.EncryptedContent_MessageUpdate()
      ..type = type
      ..senderMessageId = targetMessageId
      ..timestamp = Int64(DateTime.now().millisecondsSinceEpoch);
    if (text != null) update.text = text;
    final content = pb.EncryptedContent()
      ..groupId = defaultGroup!.groupId
      ..messageUpdate = update;
    await sendEncryptedContent(target, content);
  }

  Future<void> sendMedia(TestClient target, String senderMessageId, pb.EncryptedContent_Media_Type type) async {
    final content = pb.EncryptedContent()
      ..groupId = defaultGroup!.groupId
      ..media = (pb.EncryptedContent_Media()
        ..senderMessageId = senderMessageId
        ..type = type
        ..requiresAuthentication = false
        ..timestamp = Int64(DateTime.now().millisecondsSinceEpoch));
    await sendEncryptedContent(target, content);
  }

  Future<Message> expectMessage(bool Function(Message) predicate) async {
    for (var i = 0; i < 500; i++) {
      final msg = await run(() async {
        final msgs = await env.db.select(env.db.messages).get();
        return msgs.firstWhereOrNull(predicate);
      });
      if (msg != null) return msg;
      await Future.delayed(const Duration(milliseconds: 10));
    }
    throw Exception('Message matching predicate not received');
  }

  Future<Reaction> expectReaction(String messageId, String emoji) async {
    for (var i = 0; i < 500; i++) {
      final reaction = await run(() async {
         final reactions = await (env.db.select(env.db.reactions)..where((t) => t.messageId.equals(messageId))).get();
         return reactions.firstWhereOrNull((r) => r.emoji == emoji);
      });
      if (reaction != null) return reaction;
      await Future.delayed(const Duration(milliseconds: 10));
    }
    throw Exception('Reaction $emoji not received on message $messageId');
  }
}
