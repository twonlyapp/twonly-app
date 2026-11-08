import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/message_enums.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_vacation.entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';

final _sentAt = DateTime(2026, 5, 2, 10);

StoredMessage _message(List<int>? payload, {int? senderId = 42}) =>
    StoredMessage(
      groupId: 'chat',
      messageId: 'vacation',
      senderId: senderId,
      type: MessageType.onVacation.name,
      additionalMessageData: payload == null
          ? null
          : Uint8List.fromList(payload),
      mediaStored: false,
      mediaReopened: false,
      isDeletedFromSender: false,
      isWidgetMedia: false,
      isStory: false,
      createdAtSeconds: databaseSeconds(_sentAt),
    );

List<int> _vacation({
  required DateTime startsAt,
  required DateTime endsAt,
  String icon = '⛵',
}) => (AdditionalMessageData()
      ..type = AdditionalMessageData_Type.VACATION
      ..vacation = (VacationData()
        ..startsAtMs = Int64(startsAt.millisecondsSinceEpoch)
        ..endsAtMs = Int64(endsAt.millisecondsSinceEpoch)
        ..icon = icon))
    .writeToBuffer();

BubbleInfo _info() => BubbleInfo()
  ..text = ''
  ..textColor = Colors.white
  ..displayTime = true
  ..displayUserName = ''
  ..color = Colors.blue
  ..padding = EdgeInsets.zero
  ..minWidth = 0;

void main() {
  setUpAll(() => initializeDateFormatting('de'));

  Future<void> show(
    WidgetTester tester,
    StoredMessage message, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ChatVacationEntry(
            message: message,
            borderRadius: BorderRadius.circular(12),
            info: _info(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  Finder emoji(String value) => find.byWidgetPredicate(
    (widget) => widget is EmojiAnimationComp && widget.emoji == value,
  );

  // Five days from May 2: the window ends at midnight starting May 7, so the
  // last vacation day shown is May 6.
  final fiveDays = _vacation(startsAt: _sentAt, endsAt: DateTime(2026, 5, 7));

  testWidgets('a vacation shows its last day, not the midnight after it', (
    tester,
  ) async {
    await show(tester, _message(fiveDays));

    final lastDay = DateFormat.MMMEd('en').format(DateTime(2026, 5, 6));
    expect(
      find.text('On vacation until $lastDay. The flames are frozen until then.'),
      findsOneWidget,
    );
    expect(emoji('⛵'), findsOneWidget);
  });

  testWidgets('the date follows the app language', (tester) async {
    await show(tester, _message(fiveDays), locale: const Locale('de'));

    final lastDay = DateFormat.MMMEd('de').format(DateTime(2026, 5, 6));
    expect(
      find.text(
        'Im Urlaub bis $lastDay. Bis dahin sind die Flammen eingefroren.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the same entry reads the same on the sender side', (
    tester,
  ) async {
    await show(tester, _message(fiveDays, senderId: null));
    expect(find.textContaining('On vacation until'), findsOneWidget);
  });

  for (final (label, endsAt) in [
    ('ended later that day', _sentAt.subtract(const Duration(hours: 10))),
    ('ended on its first day', _sentAt),
  ]) {
    testWidgets('an early end says the sender is back: $label', (
      tester,
    ) async {
      await show(
        tester,
        _message(_vacation(startsAt: _sentAt, endsAt: endsAt)),
      );
      expect(
        find.text('Back from vacation. The flames count again.'),
        findsOneWidget,
      );
    });
  }

  testWidgets('an unknown icon from a newer release is still shown', (
    tester,
  ) async {
    await show(
      tester,
      _message(
        _vacation(startsAt: _sentAt, endsAt: DateTime(2026, 5, 7), icon: '🏝️'),
      ),
    );
    expect(emoji('🏝️'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a junk icon falls back to the default', (tester) async {
    await show(
      tester,
      _message(
        _vacation(
          startsAt: _sentAt,
          endsAt: DateTime(2026, 5, 7),
          icon: '<script>',
        ),
      ),
    );
    expect(emoji('🏕️'), findsOneWidget);
    expect(find.textContaining('script'), findsNothing);
  });

  for (final (label, payload) in [
    ('no payload', null),
    ('a broken payload', [0xff, 0xff, 0xff]),
    (
      'a payload without a vacation',
      (AdditionalMessageData()..type = AdditionalMessageData_Type.VACATION)
          .writeToBuffer(),
    ),
  ]) {
    testWidgets('$label shows nothing', (tester) async {
      await show(tester, _message(payload));
      expect(find.byType(EmojiAnimationComp), findsNothing);
      expect(find.byType(Text), findsNothing);
    });
  }
}
