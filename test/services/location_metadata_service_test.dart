import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/services/location_metadata.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/filter.layer.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/filters/location_filter.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/sticker.layer.dart';

import '../mocks/user_config.dart';

class _LocationApi implements RustLibApi {
  int warmups = 0;
  int fixes = 0;
  Future<StickerLocation?> Function()? pendingFix;
  StickerLocation? location = const StickerLocation(
    latitude: 52.52,
    longitude: 13.405,
  );

  @override
  Future<void> crateBridgeApiRustApiPrewarmMemoryLocation() async => warmups++;

  @override
  Future<StickerLocation?>
  crateBridgeApiRustApiCurrentLocationForSticker() async {
    fixes++;
    return pendingFix == null ? location : await pendingFix!();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('eu.twonly/location_metadata');
  final api = _LocationApi();
  var permission = true;
  final calls = <MethodCall>[];
  Future<String?> Function()? geocode;
  Future<bool> Function()? permissionCheck;

  setUpAll(() {
    AppEnvironment.initTesting();
    RustLib.initMock(api: api);
  });
  tearDownAll(RustLib.dispose);

  setUp(() async {
    await locator.reset();
    locator.registerSingleton<UserService>(UserService());
    userService
      ..currentUser = testUserConfig(
        userId: 1,
        username: 'me',
        displayName: 'Me',
        subscriptionPlan: 'Free',
        currentSetupPage: null,
        appVersion: 100,
      )
      ..isUserCreated = true;
    userService.currentUser.language = 'en';
    api
      ..warmups = 0
      ..fixes = 0
      ..pendingFix = null
      ..location = const StickerLocation(latitude: 52.52, longitude: 13.405);
    permission = true;
    calls.clear();
    geocode = null;
    permissionCheck = null;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      switch (call.method) {
        case 'hasPrecisePermission':
          return permissionCheck == null
              ? permission
              : await permissionCheck!();
        case 'requestPrecisePermission':
          return permission;
        case 'resolveCity':
          return geocode == null ? 'Berlin' : await geocode!();
      }
      throw MissingPluginException(call.method);
    });
  });

  tearDown(() async {
    LocationMetadataService.dispose();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await locator.reset();
  });

  Future<void> showLocationFilter(WidgetTester tester) async {
    for (var i = 0; i < 2; i++) {
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump();
  }

  Future<void> flush() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Widget app(Widget child) => MaterialApp(
    theme: lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  test('default-disabled startup does not touch native location', () async {
    LocationMetadataService.initialize();
    await flush();
    expect(await LocationMetadataService.currentCity(), isNull);
    expect(calls, isEmpty);
    expect(api.warmups, 0);
    expect(api.fixes, 0);
  });

  test('Memories alone warms shared coordinates without city lookup', () async {
    userService.currentUser.storeLocationInMemories = true;
    LocationMetadataService.initialize();
    await flush();
    expect(api.warmups, 1);
    expect(api.fixes, 0);
    expect(calls.map((call) => call.method), ['hasPrecisePermission']);
  });

  test(
    'sticker startup resolves and caches city without permission prompt',
    () async {
      userService.currentUser.enableLocationSticker = true;
      LocationMetadataService.initialize();
      await flush();
      expect(
        await LocationMetadataService.currentCity(languageTag: 'en'),
        'Berlin',
      );
      expect(api.warmups, 1);
      expect(api.fixes, 1);
      final lookup = calls.singleWhere((call) => call.method == 'resolveCity');
      expect(lookup.arguments, {
        'latitude': 52.52,
        'longitude': 13.405,
        'locale': 'en',
      });
      expect(
        calls.any((call) => call.method == 'requestPrecisePermission'),
        isFalse,
      );
    },
  );

  test('revoked permission discards even a cached city', () async {
    userService.currentUser.enableLocationSticker = true;
    expect(await LocationMetadataService.currentCity(), 'Berlin');
    permission = false;
    expect(await LocationMetadataService.currentCity(), isNull);
    expect(api.fixes, 1);
  });

  test('permission denial on startup does not acquire or geocode', () async {
    userService.currentUser.enableLocationSticker = true;
    permission = false;
    LocationMetadataService.initialize();
    await flush();
    expect(api.warmups, 0);
    expect(api.fixes, 0);
    expect(calls.map((call) => call.method), ['hasPrecisePermission']);
  });

  test('disabling during geocoding discards the pending city', () async {
    userService.currentUser.enableLocationSticker = true;
    final result = Completer<String?>();
    geocode = () => result.future;
    final city = LocationMetadataService.currentCity();
    await flush();
    userService.currentUser.enableLocationSticker = false;
    result.complete('Berlin');
    expect(await city, isNull);
  });

  test('disabling during permission recheck prevents city lookup', () async {
    userService.currentUser.enableLocationSticker = true;
    var checks = 0;
    permissionCheck = () async {
      if (++checks == 2) userService.currentUser.enableLocationSticker = false;
      return true;
    };
    expect(await LocationMetadataService.currentCity(), isNull);
    expect(calls.any((call) => call.method == 'resolveCity'), isFalse);
  });

  test('disabling during final permission recheck discards city', () async {
    userService.currentUser.enableLocationSticker = true;
    var checks = 0;
    permissionCheck = () async {
      if (++checks == 3) userService.currentUser.enableLocationSticker = false;
      return true;
    };
    expect(await LocationMetadataService.currentCity(), isNull);
    expect(calls.any((call) => call.method == 'resolveCity'), isTrue);
  });

  test(
    'failed geocoding is retryable and concurrent lookups are shared',
    () async {
      userService.currentUser.enableLocationSticker = true;
      geocode = () async => throw PlatformException(code: 'offline');
      final cities = await Future.wait([
        LocationMetadataService.currentCity(),
        LocationMetadataService.currentCity(),
      ]);
      expect(cities, ['52.5200, 13.4050', '52.5200, 13.4050']);
      expect(api.fixes, 1);
      geocode = null;
      expect(await LocationMetadataService.currentCity(), 'Berlin');
      expect(api.fixes, 2);
    },
  );

  test('enabling and foreground resume start location automatically', () async {
    LocationMetadataService.initialize();
    userService.currentUser.enableLocationSticker = true;
    userService.triggerUserUpdate();
    await flush();
    expect(api.warmups, 1);
    expect(api.fixes, 1);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(await LocationMetadataService.currentCity(), isNull);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await flush();
    expect(api.warmups, 2);
    expect(api.fixes, 2);
  });

  testWidgets('enabled city is the filter immediately after date and time', (
    tester,
  ) async {
    userService.currentUser.enableLocationSticker = true;
    final layer = FilterLayerData(key: GlobalKey());
    await tester.pumpWidget(app(FilterLayer(layerData: layer)));
    await tester.pumpAndSettle();
    expect(layer.page, 1);
    await tester.drag(find.byType(PageView), const Offset(-800, 0));
    await tester.pumpAndSettle();
    expect(layer.page, 2);
    await tester.drag(find.byType(PageView), const Offset(-800, 0));
    await tester.pumpAndSettle();
    expect(layer.page, 3);
    expect(find.text('Berlin'), findsOneWidget);
    expect(find.byType(LocationFilter), findsOneWidget);
    expect(
      calls.any((call) => call.method == 'requestPrecisePermission'),
      false,
    );
  });

  testWidgets('disabled city never adds a filter or requests location', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(FilterLayer(layerData: FilterLayerData(key: GlobalKey()))),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-800, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-800, 0));
    await tester.pumpAndSettle();
    expect(find.byType(LocationFilter), findsNothing);
    expect(calls, isEmpty);
  });

  testWidgets('dots stop when a fix arrives before geocoding finishes', (
    tester,
  ) async {
    userService.currentUser.enableLocationSticker = true;
    final result = Completer<String?>();
    final fix = Completer<StickerLocation?>();
    api.pendingFix = () => fix.future;
    geocode = () => result.future;
    final layer = FilterLayerData(key: GlobalKey());
    await tester.pumpWidget(app(FilterLayer(layerData: layer)));
    await showLocationFilter(tester);
    expect(layer.page, 3);
    expect(find.byType(ThreeRotatingDots), findsOneWidget);
    fix.complete(const StickerLocation(latitude: 52.52, longitude: 13.405));
    await tester.pumpAndSettle();
    expect(find.byType(ThreeRotatingDots), findsNothing);
    expect(find.text('52.5200, 13.4050'), findsOneWidget);
    result.complete('Berlin');
    await tester.pumpAndSettle();
    expect(layer.page, 3);
    expect(find.text('Berlin'), findsOneWidget);
    expect(find.byType(ThreeRotatingDots), findsNothing);
  });

  testWidgets('editor receives coordinates from a pending startup lookup', (
    tester,
  ) async {
    userService.currentUser.enableLocationSticker = true;
    final result = Completer<String?>();
    geocode = () => result.future;
    LocationMetadataService.initialize();
    await tester.runAsync(flush);
    expect(api.fixes, 1);
    await tester.pumpWidget(
      app(FilterLayer(layerData: FilterLayerData(key: GlobalKey()))),
    );
    await showLocationFilter(tester);
    await tester.pumpAndSettle();
    expect(find.byType(ThreeRotatingDots), findsNothing);
    expect(find.text('52.5200, 13.4050'), findsOneWidget);
    expect(api.fixes, 1);
    result.complete('Berlin');
    await tester.pumpAndSettle();
    expect(find.text('Berlin'), findsOneWidget);
  });

  testWidgets('failed geocoding keeps the available location without loading', (
    tester,
  ) async {
    userService.currentUser.enableLocationSticker = true;
    geocode = () async => throw PlatformException(code: 'offline');
    await tester.pumpWidget(
      app(FilterLayer(layerData: FilterLayerData(key: GlobalKey()))),
    );
    await showLocationFilter(tester);
    await tester.pumpAndSettle();
    expect(find.text('52.5200, 13.4050'), findsOneWidget);
    expect(find.byType(ThreeRotatingDots), findsNothing);
    await tester.pump(const Duration(seconds: 10));
    expect(api.fixes, 1);
  });

  testWidgets('missing city and country use the available coordinates', (
    tester,
  ) async {
    userService.currentUser.enableLocationSticker = true;
    geocode = () async => null;
    await tester.pumpWidget(
      app(FilterLayer(layerData: FilterLayerData(key: GlobalKey()))),
    );
    await showLocationFilter(tester);
    await tester.pumpAndSettle();
    expect(find.text('52.5200, 13.4050'), findsOneWidget);
    expect(find.byType(ThreeRotatingDots), findsNothing);
  });

  testWidgets(
    'geocoding timeout keeps coordinates instead of restarting loading',
    (tester) async {
      userService.currentUser.enableLocationSticker = true;
      final result = Completer<String?>();
      geocode = () => result.future;
      await tester.pumpWidget(
        app(FilterLayer(layerData: FilterLayerData(key: GlobalKey()))),
      );
      await showLocationFilter(tester);
      await tester.pumpAndSettle();
      expect(find.text('52.5200, 13.4050'), findsOneWidget);
      await tester.pump(const Duration(seconds: 13));
      await tester.pumpAndSettle();
      expect(find.text('52.5200, 13.4050'), findsOneWidget);
      expect(find.byType(ThreeRotatingDots), findsNothing);
      expect(api.fixes, 1);
      result.complete(null);
      await tester.pump();
    },
  );

  testWidgets('disabling the selected city returns to the unfiltered photo', (
    tester,
  ) async {
    userService.currentUser.enableLocationSticker = true;
    final layer = FilterLayerData(key: GlobalKey());
    await tester.pumpWidget(app(FilterLayer(layerData: layer)));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();
    }
    expect(find.text('Berlin'), findsOneWidget);
    userService.currentUser.enableLocationSticker = false;
    userService.triggerUserUpdate();
    await tester.pumpAndSettle();
    expect(find.byType(LocationFilter), findsNothing);
    expect(layer.page, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no location yet keeps dots and retries until a fix arrives', (
    tester,
  ) async {
    userService.currentUser.enableLocationSticker = true;
    api.location = null;
    await tester.pumpWidget(
      app(FilterLayer(layerData: FilterLayerData(key: GlobalKey()))),
    );
    await showLocationFilter(tester);
    expect(find.byType(LocationFilter), findsOneWidget);
    expect(find.byType(ThreeRotatingDots), findsOneWidget);
    expect(api.fixes, 1);
    api.location = const StickerLocation(latitude: 52.52, longitude: 13.405);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Berlin'), findsOneWidget);
    expect(find.byType(ThreeRotatingDots), findsNothing);
    expect(api.fixes, 2);
  });

  testWidgets('country returned by native geocoding is shown in the filter', (
    tester,
  ) async {
    userService.currentUser.enableLocationSticker = true;
    geocode = () async => 'Germany';
    await tester.pumpWidget(
      app(FilterLayer(layerData: FilterLayerData(key: GlobalKey()))),
    );
    await showLocationFilter(tester);
    await tester.pumpAndSettle();
    expect(find.text('Germany'), findsOneWidget);
  });

  testWidgets('disabling while loading removes dots and cancels retries', (
    tester,
  ) async {
    userService.currentUser.enableLocationSticker = true;
    api.location = null;
    final layer = FilterLayerData(key: GlobalKey());
    await tester.pumpWidget(app(FilterLayer(layerData: layer)));
    await showLocationFilter(tester);
    expect(find.byType(ThreeRotatingDots), findsOneWidget);
    userService.currentUser.enableLocationSticker = false;
    userService.triggerUserUpdate();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(LocationFilter), findsNothing);
    expect(layer.page, 1);
    expect(api.fixes, 1);
  });

  testWidgets('closing a loading editor cancels its retry', (tester) async {
    userService.currentUser.enableLocationSticker = true;
    api.location = null;
    await tester.pumpWidget(
      app(FilterLayer(layerData: FilterLayerData(key: GlobalKey()))),
    );
    await showLocationFilter(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
    expect(api.fixes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('city layer shares sticker dragging and keeps its city', (
    tester,
  ) async {
    final layer = LocationStickerLayerData(
      key: GlobalKey(),
      city: 'Berlin',
      offset: const Offset(80, 80),
    );
    await tester.pumpWidget(app(StickerLayer(layerData: layer)));
    await tester.drag(find.text('Berlin'), const Offset(40, 20));
    await tester.pump();
    expect(layer.offset.dx, greaterThan(80));
    expect(layer.city, 'Berlin');
    expect(tester.takeException(), isNull);
  });
}
