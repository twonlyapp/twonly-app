import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/visual/views/settings/help/faq.view.dart';

void main() {
  late Directory directory;
  final faq = jsonEncode({
    'en': {
      'general': {
        'meta': {'title': 'Getting started', 'desc': 'FAQ', 'priority': 1},
        'questions': <Object>[],
      },
    },
  });

  setUp(() {
    directory = Directory.systemTemp.createTempSync('twonly-faq-');
    AppEnvironment.initTesting(
      customCacheDir: directory.path,
      customSupportDir: directory.path,
    );
  });
  tearDown(() => directory.deleteSync(recursive: true));

  Future<void> show(WidgetTester tester, http.Client client) =>
      http.runWithClient(
        () => tester.pumpWidget(
          const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: FaqView(),
          ),
        ),
        () => client,
      );

  testWidgets('a successful response renders even if caching fails', (
    tester,
  ) async {
    Directory('${directory.path}/faq.json').createSync();
    await show(tester, MockClient((_) async => http.Response(faq, 200)));
    await tester.pumpAndSettle();
    expect(find.text('Getting started'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-success responses fall back to a valid cache', (
    tester,
  ) async {
    File('${directory.path}/faq.json').writeAsStringSync(faq);
    await show(tester, MockClient((_) async => http.Response('', 503)));
    await tester.pumpAndSettle();
    expect(find.text('Getting started'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unusable response preserves and displays the valid cache', (
    tester,
  ) async {
    final cache = File('${directory.path}/faq.json')..writeAsStringSync(faq);
    await show(tester, MockClient((_) async => http.Response('{}', 200)));
    await tester.pumpAndSettle();
    expect(find.text('Getting started'), findsOneWidget);
    expect(cache.readAsStringSync(), faq);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline with a corrupt cache fails safely and can retry', (
    tester,
  ) async {
    File('${directory.path}/faq.json').writeAsStringSync('invalid JSON');
    var requests = 0;
    final client = MockClient((_) async {
      if (requests++ == 0) throw const SocketException('offline');
      return http.Response(faq, 200);
    });
    await show(tester, client);
    await tester.pumpAndSettle();
    expect(find.text('Could not load the FAQ.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await http.runWithClient(
      () => tester.tap(find.byType(TextButton)),
      () => client,
    );
    await tester.pumpAndSettle();
    expect(find.text('Getting started'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final body in ['invalid JSON', '{}', '{"fr": {}}']) {
    testWidgets('missing FAQ data fails safely: $body', (tester) async {
      await show(tester, MockClient((_) async => http.Response(body, 200)));
      await tester.pumpAndSettle();
      expect(find.text('Could not load the FAQ.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('an unfinished request times out instead of loading forever', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    await show(tester, MockClient((_) => response.future));
    await tester.pump(const Duration(seconds: 16));
    await tester.pumpAndSettle();
    expect(find.text('Could not load the FAQ.'), findsOneWidget);
    response.complete(http.Response(faq, 200));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing the screen before the response does not set state', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    await show(tester, MockClient((_) => response.future));
    await tester.pumpWidget(const SizedBox());
    response.complete(http.Response(faq, 200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
