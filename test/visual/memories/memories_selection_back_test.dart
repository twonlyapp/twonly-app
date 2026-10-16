import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/memories/components/memory_thumbnail.comp.dart';
import 'package:twonly/src/visual/views/memories/memories.view.dart';

import '../../mocks/user_config.dart';

class _MemoriesApi implements RustLibApi {
  final cloudDeletes = <String>[];
  Exception? cloudError;

  @override
  Future<void> crateBridgeApiRustApiDeleteMemory({
    required String mediaId,
  }) async {
    cloudDeletes.add(mediaId);
    if (cloudError != null) throw cloudError!;
  }

  @override
  Future<void> crateBridgeApiRustApiRemoveMediaFiles({
    required String mediaId,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PurchasesProvider extends ChangeNotifier
    with DiagnosticableTreeMixin
    implements PurchasesProvider {
  @override
  SubscriptionPlan get plan => SubscriptionPlan.Free;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _MemoriesApi();
  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);
  late TwonlyDB database;
  late Directory support;
  late _PurchasesProvider purchases;

  setUp(() async {
    api
      ..cloudDeletes.clear()
      ..cloudError = null;
    database = TwonlyDB(NativeDatabase.memory());
    locator
      ..registerSingleton<TwonlyDB>(database)
      ..registerSingleton<UserService>(UserService());
    userService.currentUser = testUserConfig(
      userId: 1,
      username: 'test',
      displayName: 'Test',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 1,
    )..hideMemoriesBackupPromo = true;
    purchases = _PurchasesProvider();
    support = Directory.systemTemp.createTempSync('memories-selection-test-');
    AppEnvironment.initTesting(customSupportDir: support.path);
    await database.customStatement(
      "INSERT INTO media_files(media_id, type, stored, has_thumbnail) VALUES('first', 'image', 1, 1), ('second', 'image', 1, 1)",
    );
    for (final file
        in await database.mediaFilesDao.watchAllStoredMediaFiles().first) {
      MediaFileService(file).thumbnailPath.writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
    }
  });

  tearDown(() async {
    await locator.unregister<UserService>();
    await locator.unregister<TwonlyDB>();
    await database.close();
    purchases.dispose();
    support.deleteSync(recursive: true);
  });

  for (final cloudFailure in [false, true]) {
    testWidgets(
      cloudFailure
          ? 'failed cloud deletion is shown and keeps the memory selected'
          : 'missing local image can be deleted from the memories grid',
      (tester) async {
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        });
        if (cloudFailure) {
          await tester.runAsync(
            () => database.mediaFilesDao.updateMedia(
              'first',
              const MediaFilesCompanion(cloudState: Value(CloudState.uploaded)),
            ),
          );
          api.cloudError = Exception('API error code 500');
        } else {
          // A request for a nonexistent cloud row would fail in the old path.
          api.cloudError = Exception('API error code 0');
        }
        await tester.pumpWidget(
          ChangeNotifierProvider<PurchasesProvider>.value(
            value: purchases,
            child: MaterialApp(
              theme: lightTheme,
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const MemoriesView(),
            ),
          ),
        );
        // Let the gallery's database subscription replace its process cache.
        for (var i = 0; i < 3; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pumpAndSettle();
        }
        final target = find.byWidgetPredicate(
          (widget) =>
              widget is MemoriesThumbnailComp &&
              widget.galleryItem.mediaService.mediaFile.mediaId == 'first',
        );
        expect(target, findsOneWidget);
        if (cloudFailure) {
          expect(
            tester
                .widget<MemoriesThumbnailComp>(target)
                .galleryItem
                .mediaService
                .mediaFile
                .cloudState
                .name,
            'uploaded',
          );
        }
        await tester.longPress(target);
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();
        expect(find.text('Are you sure?'), findsOneWidget);
        await tester.tap(
          find.ancestor(
            of: find.text(cloudFailure ? 'Completely' : 'Delete'),
            matching: find.byType(MyButton),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 350)),
        );
        await tester.pumpAndSettle();

        if (cloudFailure) {
          expect(api.cloudDeletes, ['first']);
          expect(target, findsOneWidget);
          expect(
            tester.widget<MemoriesThumbnailComp>(target).isSelected,
            isTrue,
          );
          expect(find.textContaining('API error code 500'), findsOneWidget);
        } else {
          expect(api.cloudDeletes, isEmpty);
          expect(target, findsNothing);
          expect(
            await tester.runAsync(
              () => database.mediaFilesDao.getMediaFileById('first'),
            ),
            isNull,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }

  for (final isRoot in [true, false]) {
    testWidgets(
      'back clears all selected memories on ${isRoot ? 'root' : 'pushed'} route',
      (tester) async {
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          ChangeNotifierProvider<PurchasesProvider>.value(
            value: purchases,
            child: MaterialApp(
              theme: lightTheme,
              navigatorKey: navigator,
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: isRoot
                  ? const MemoriesView()
                  : const Scaffold(body: Text('Previous screen')),
            ),
          ),
        );
        if (!isRoot) {
          navigator.currentState!.push(
            MaterialPageRoute<void>(builder: (_) => const MemoriesView()),
          );
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();

        final thumbnails = find.byType(MemoriesThumbnailComp);
        expect(thumbnails, findsNWidgets(2));
        await tester.longPress(thumbnails.first);
        await tester.pumpAndSettle();
        await tester.tap(thumbnails.last);
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<MemoriesThumbnailComp>(thumbnails)
              .every((thumbnail) => thumbnail.isSelected),
          isTrue,
        );

        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();
        expect(find.byType(MemoriesView), findsOneWidget);
        expect(
          tester
              .widgetList<MemoriesThumbnailComp>(thumbnails)
              .every(
                (thumbnail) =>
                    !thumbnail.isSelected && !thumbnail.selectionMode,
              ),
          isTrue,
        );

        expect(await navigator.currentState!.maybePop(), !isRoot);
        await tester.pumpAndSettle();
        if (!isRoot) {
          expect(find.text('Previous screen'), findsOneWidget);
          expect(find.byType(MemoriesView), findsNothing);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }
}
