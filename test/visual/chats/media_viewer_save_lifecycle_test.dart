import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/groups.dao.dart';
import 'package:twonly/src/database/daos/messages.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/media_viewer.view.dart';

class _GalleryApi implements RustLibApi {
  final receipts = <pb.EncryptedContent>[];
  Completer<void>? pendingReceipt;

  @override
  Future<void> crateBridgeApiRustApiSendEncryptedContentToGroup({
    required String groupId,
    required List<int> content,
    String? messageId,
    bool? onlySendIfNoReceiptsAreOpen,
  }) async {
    expectSync(groupId, 'chat');
    receipts.add(pb.EncryptedContent.fromBuffer(content));
    await pendingReceipt?.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ViewerMessages implements MessagesDao {
  final storedMessages = <String>[];

  @override
  Stream<List<Message>> watchMediaNotOpened(String groupId) =>
      const Stream.empty();

  @override
  Future<void> updateMessageId(
    String messageId,
    MessagesCompanion updatedValues,
  ) async {
    expectSync(updatedValues.mediaStored.value, isTrue);
    storedMessages.add(messageId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ViewerGroups implements GroupsDao {
  @override
  Future<void> updateGroup(String groupId, GroupsCompanion updates) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ViewerDatabase implements TwonlyDB {
  @override
  final _ViewerMessages messagesDao = _ViewerMessages();
  @override
  final _ViewerGroups groupsDao = _ViewerGroups();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ViewerGroup implements Group {
  @override
  String get groupId => 'chat';
  @override
  String get groupName => 'Chat';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PendingMedia implements MediaFileService {
  final stored = Completer<void>();
  int saves = 0;

  @override
  Future<void> storeMediaFile() {
    saves++;
    return stored.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const screenProtector = MethodChannel('screen_protector');
  final api = _GalleryApi();
  late _ViewerDatabase database;
  late _PendingMedia media;

  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    api
      ..receipts.clear()
      ..pendingReceipt = null;
    await locator.reset();
    database = _ViewerDatabase();
    locator.registerSingleton<TwonlyDB>(database);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      screenProtector,
      (_) async => null,
    );
  });

  tearDown(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      screenProtector,
      null,
    );
    await locator.reset();
  });

  Future<Future<void> Function()> mountViewer(WidgetTester tester) async {
    media = _PendingMedia();
    await tester.pumpWidget(
      MaterialApp(theme: lightTheme, home: MediaViewerView(_ViewerGroup())),
    );
    final dynamic state = tester.state(find.byType(MediaViewerView));
    // Supply a pending save without starting media downloads or playback.
    // ignore: avoid_dynamic_calls, cascade_invocations
    state
      ..currentMedia = media
      ..currentMessage = Message(
        groupId: 'chat',
        messageId: 'message',
        type: 'media',
        mediaId: 'image',
        mediaStored: false,
        mediaReopened: false,
        isDeletedFromSender: false,
        isWidgetMedia: false,
        isStory: false,
        createdAt: DateTime(2026),
      );
    // ignore: avoid_dynamic_calls
    return state.onPressedSaveToGallery as Future<void> Function();
  }

  testWidgets('a save callback after disposal does nothing', (tester) async {
    final save = await mountViewer(tester);
    await tester.pumpWidget(const SizedBox.shrink());

    await save();

    expect(media.saves, 0);
    expect(database.messagesDao.storedMessages, isEmpty);
    expect(api.receipts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'closing during a save still stores the message and sends its receipt',
    (
      tester,
    ) async {
      final save = await mountViewer(tester);
      api.pendingReceipt = Completer<void>();
      final saving = save();
      expect(media.saves, 1);

      // Remove the viewer before its next rebuild, while storage is pending.
      await tester.pumpWidget(const SizedBox.shrink());
      media.stored.complete();
      await tester.pump();
      expect(database.messagesDao.storedMessages, ['message']);
      expect(api.receipts, hasLength(1));

      api.pendingReceipt!.complete();
      await tester.pump();
      await saving;

      final receipt = api.receipts.single.mediaUpdate;
      expect(receipt.targetMessageId, 'message');
      expect(receipt.type, pb.EncryptedContent_MediaUpdate_Type.STORED);
      expect(tester.takeException(), isNull);
    },
  );
}
