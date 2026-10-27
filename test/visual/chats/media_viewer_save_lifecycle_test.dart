import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/media_viewer.view.dart';

import '../../mocks/database_watch.dart';

class _TestSession implements DatabaseSession {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GalleryApi implements RustLibApi {
  final storedMessages = <String>[];
  @override
  DatabaseSession crateBridgeDatabaseDatabaseSessionNew() => _TestSession();
  @override
  DatabaseWatch crateBridgeDatabaseDatabaseWatchNew() => TestDatabaseWatch();
  @override
  Stream<List<StoredMessage>> crateBridgeDatabaseMessagesWatchMessages({
    required MessageQuery input,
    required DatabaseWatch control,
  }) => const Stream.empty();
  @override
  Future<void> crateBridgeDatabaseMessagesUpdateMessages({
    required String id,
    required bool byMedia,
    required MessagePatch patch,
    required DatabaseSession transaction,
  }) async {
    expectSync(patch.mediaStored, isTrue);
    storedMessages.add(id);
  }

  @override
  Future<void> crateBridgeDatabaseGroupsUpdateGroup({
    required String id,
    required GroupPatch patch,
    required DatabaseSession transaction,
  }) async {}

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
  late _PendingMedia media;

  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    api
      ..receipts.clear()
      ..pendingReceipt = null;
    await locator.reset();
    api.storedMessages.clear();

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
      ..currentMessage = StoredMessage(
        groupId: 'chat',
        messageId: 'message',
        type: 'media',
        mediaId: 'image',
        mediaStored: false,
        mediaReopened: false,
        isDeletedFromSender: false,
        isWidgetMedia: false,
        isStory: false,
        createdAtSeconds: databaseSeconds(DateTime(2026)),
      );
    // ignore: avoid_dynamic_calls
    return state.onPressedSaveToGallery as Future<void> Function();
  }

  testWidgets('a save callback after disposal does nothing', (tester) async {
    final save = await mountViewer(tester);
    await tester.pumpWidget(const SizedBox.shrink());

    await save();

    expect(media.saves, 0);
    expect(api.storedMessages, isEmpty);
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
      expect(api.storedMessages, ['message']);
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
