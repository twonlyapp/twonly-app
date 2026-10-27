import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/visual/views/chats/media_viewer_components/emoji_reactions_row.comp.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/reaction_buttons.comp.dart';

class _TestSession implements DatabaseSession {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReactionApi implements RustLibApi {
  final reactions = <pb.EncryptedContent_Reaction>[];
  Completer<void>? pendingSend;

  @override
  DatabaseSession crateBridgeDatabaseDatabaseSessionNew() => _TestSession();

  @override
  Future<void> crateBridgeDatabaseReactionsUpdateOwnReaction({
    required String message,
    required String emoji,
    required bool remove,
    required DatabaseSession transaction,
  }) async {}

  @override
  Future<void> crateBridgeApiRustApiSendEncryptedContentToGroup({
    required String groupId,
    required List<int> content,
    String? messageId,
    bool? onlySendIfNoReceiptsAreOpen,
  }) async {
    expectSync(groupId, 'chat');
    reactions.add(pb.EncryptedContent.fromBuffer(content).reaction);
    await pendingSend?.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _ReactionApi();

  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    await locator.reset();
    api
      ..reactions.clear()
      ..pendingSend = null;
  });

  tearDown(locator.reset);

  Future<void> mountReaction(WidgetTester tester, VoidCallback hide) {
    api.pendingSend = Completer<void>();
    return tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: EmojiReactionWidget(
            messageId: 'message',
            groupId: 'chat',
            hide: hide,
            show: true,
            emoji: '🧪',
            emojiKey: GlobalKey<EmojiFloatWidgetState>(),
          ),
        ),
      ),
    );
  }

  testWidgets('closing the viewer during a reaction still sends it safely', (
    tester,
  ) async {
    var hideCalls = 0;
    await mountReaction(tester, () => hideCalls++);
    await tester.tap(find.byType(EmojiReactionWidget));
    await tester.pump();
    expect(api.reactions, hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    api.pendingSend!.complete();
    await tester.pump();

    expect(api.reactions.single.targetMessageId, 'message');
    expect(api.reactions.single.emoji, '🧪');
    expect(hideCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a completed reaction hides the controls while still mounted', (
    tester,
  ) async {
    var hideCalls = 0;
    await mountReaction(tester, () => hideCalls++);
    await tester.tap(find.byType(EmojiReactionWidget));
    await tester.pump();
    expect(hideCalls, 0);

    api.pendingSend!.complete();
    await tester.pump();

    expect(api.reactions, hasLength(1));
    expect(hideCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
