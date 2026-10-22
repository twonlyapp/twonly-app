import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/views/memories/components/memory_details.bottom_sheet.dart';

MediaFile _media({double? latitude, double? longitude, String? status}) =>
    MediaFile(
      mediaId: 'capture',
      typeName: MediaType.image.name,
      cloudStateName: CloudState.none.name,
      requiresAuthentication: false,
      stored: true,
      isDraftMedia: false,
      isWidgetMedia: false,
      isFavorite: false,
      hasCropAnalyzed: false,
      hasThumbnail: false,
      galleryExportPending: false,
      createdAtSeconds: databaseSeconds(DateTime(2026, 10, 9, 14, 35)),
      sizeInBytes: 1024,
      locationLatitude: latitude,
      locationLongitude: longitude,
      locationAccuracy: 8.4,
      locationStatus: status,
    );

Widget _app(MediaFile media) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: MemoryDetailsSheet(media: media)),
);

void main() {
  testWidgets('shows capture time, size and coordinates without accuracy', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_media(latitude: 52.52, longitude: 13.405, status: 'resolved')),
    );
    expect(find.text('Details'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
    expect(find.text('File size'), findsOneWidget);
    expect(find.text('52.520000, 13.405000'), findsOneWidget);
    expect(find.textContaining('Accuracy'), findsNothing);
    expect(find.text('Open in map'), findsOneWidget);
  });

  testWidgets('shows pending acquisition and then the resolved location', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_media(status: 'pending')));
    expect(find.text('Finding capture location…'), findsOneWidget);
    expect(find.text('Open in map'), findsNothing);
    await tester.pumpWidget(
      _app(_media(latitude: 0, longitude: 0, status: 'resolved')),
    );
    expect(find.text('Finding capture location…'), findsNothing);
    expect(find.text('0.000000, 0.000000'), findsOneWidget);
    expect(find.text('Open in map'), findsOneWidget);
  });

  testWidgets('missing or invalid location does not offer maps', (
    tester,
  ) async {
    for (final media in [
      _media(),
      _media(latitude: 91, longitude: 13),
      _media(latitude: double.nan, longitude: 13),
    ]) {
      await tester.pumpWidget(_app(media));
      expect(find.text('No location recorded'), findsOneWidget);
      expect(find.text('Open in map'), findsNothing);
    }
  });

  testWidgets('details fit a narrow screen with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _app(
          _media(latitude: -52.52, longitude: -113.405, status: 'resolved'),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('open in map dismisses details and returns the selected image', (
    tester,
  ) async {
    final media = _media(
      latitude: 52.52,
      longitude: 13.405,
      status: 'resolved',
    );
    MediaFile? selected;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showModalBottomSheet<MediaFile>(
                  context: context,
                  builder: (_) => MemoryDetailsSheet(media: media),
                );
              },
              child: const Text('Show details'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open in map'));
    await tester.pumpAndSettle();
    expect(selected, same(media));
    expect(find.byType(MemoryDetailsSheet), findsNothing);
  });
}
