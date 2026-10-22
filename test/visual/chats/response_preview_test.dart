import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/response_container.dart';

void main() {
  testWidgets('quoted sticker keeps its image stream across chat rebuilds', (
    tester,
  ) async {
    final bytes = File('assets/images/default_avatar.png').readAsBytesSync();
    final message = StoredMessage(
      groupId: 'group',
      messageId: 'sticker',
      type: 'text',
      additionalMessageData: AdditionalMessageData(
        type: AdditionalMessageData_Type.STICKER,
        sticker: StickerData(
          version: 1,
          webp: bytes,
          sha256: sha256.convert(bytes).bytes,
          width: 64,
          height: 64,
        ),
      ).writeToBuffer(),
      mediaStored: false,
      mediaReopened: false,
      isDeletedFromSender: false,
      isWidgetMedia: false,
      isStory: false,
      createdAtSeconds: databaseSeconds(DateTime(2026)),
    );
    final group = Group(
      groupId: 'group',
      groupName: 'Chat',
      isGroupAdmin: true,
      isDirectChat: true,
      pinned: false,
      archived: false,
      joinedGroup: true,
      leftGroup: false,
      deletedContent: false,
      stateVersionId: 0,
      totalMediaCounter: 0,
      alsoBestFriend: false,
      deleteMessagesAfterMilliseconds: 0,
      createdAtSeconds: databaseSeconds(DateTime(2026)),
      flameCounter: 0,
      maxFlameCounter: 0,
      lastMessageExchangeSeconds: databaseSeconds(DateTime(2026)),
    );

    Widget app({required bool showBorder}) => MaterialApp(
      theme: lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ResponsePreview(
          message: message,
          group: group,
          showBorder: showBorder,
          useSharedData: true,
        ),
      ),
    );

    await tester.pumpWidget(app(showBorder: true));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    final provider = tester.widget<Image>(find.byType(Image)).image;
    final stream = provider.resolve(ImageConfiguration.empty).key;
    final decodedImage = tester.widget<RawImage>(find.byType(RawImage)).image;
    expect(decodedImage, isNotNull);
    expect(find.text('Sticker'), findsOneWidget);

    for (var index = 0; index < 5; index++) {
      await tester.pumpWidget(app(showBorder: index.isEven));
      final rebuiltProvider = tester.widget<Image>(find.byType(Image)).image;
      expect(
        rebuiltProvider.resolve(ImageConfiguration.empty).key,
        same(stream),
      );
      expect(
        tester.widget<RawImage>(find.byType(RawImage)).image,
        same(decodedImage),
      );
    }
  });
}
