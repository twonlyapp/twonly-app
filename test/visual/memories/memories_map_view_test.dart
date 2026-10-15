import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/visual/helpers/memory_map_countries.helper.dart';
import 'package:twonly/src/visual/themes/dark.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/memories/components/memories_map_gallery.comp.dart';
import 'package:twonly/src/visual/views/memories/memories_map.view.dart';

class _MapPlatform extends MapLibrePlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected map call: ${invocation.memberName}');

  final sources = <String, Map<String, dynamic>>{};
  final layers = <String>{};
  final styles = <String>[];
  final padding = <EdgeInsets>[];
  final projectedPoints = <math.Point>[];
  final renderingPaused = <bool>[];
  Map<String, dynamic>? creationParams;
  Size viewportSize = Size.zero;
  double projectionScale = 1;
  double west = 12;
  double east = 14;
  double north = 54;
  double south = 50;
  Future<void>? projectionBarrier;

  @override
  Widget buildView(
    Map<String, dynamic> params,
    OnPlatformViewCreatedCallback onCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) {
    if (creationParams == null) {
      creationParams = params;
      styles.add(params['styleString'] as String);
      onCreated(0);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        viewportSize = constraints.biggest;
        return const SizedBox.expand();
      },
    );
  }

  @override
  Future<void> initPlatform(int id) async {}

  @override
  Future<void> pauseMap() async => renderingPaused.add(true);

  @override
  Future<void> resumeMap() async => renderingPaused.add(false);

  @override
  Future<CameraPosition?> updateMapOptions(Map<String, dynamic> updates) async {
    final style = updates['styleString'] as String?;
    if (style != null) {
      styles.add(style);
      sources.clear();
      layers.clear();
      onMapStyleLoadedPlatform.call(null);
    }
    return null;
  }

  @override
  Future<void> addSource(String id, SourceProperties properties) async {
    sources[id] = properties.toJson();
  }

  @override
  Future<void> setGeoJsonSource(String id, Map<String, dynamic> data) async {
    sources[id]!['data'] = data;
  }

  @override
  Future<List<String>> getSourceIds() async => sources.keys.toList();

  @override
  Future<List<String>> getLayerIds() async => layers.toList();

  @override
  Future<void> removeSource(String id) async => sources.remove(id);

  @override
  Future<void> removeLayer(String id) async => layers.remove(id);

  @override
  Future<void> addHeatmapLayer(
    String sourceId,
    String layerId,
    Map<String, dynamic> properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
  }) async => layers.add(layerId);

  @override
  Future<void> addCircleLayer(
    String sourceId,
    String layerId,
    Map<String, dynamic> properties, {
    required bool enableInteraction,
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
  }) async => layers.add(layerId);

  @override
  Future<void> addSymbolLayer(
    String sourceId,
    String layerId,
    Map<String, dynamic> properties, {
    required bool enableInteraction,
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
  }) async => layers.add(layerId);

  @override
  Future<void> updateContentInsets(EdgeInsets insets, bool animated) async {
    padding.add(insets);
    // Native padding updates generate camera events. This must not cause a
    // feedback loop of padding updates and viewport refreshes.
    onCameraIdlePlatform.call(
      const CameraPosition(target: LatLng(52, 13), zoom: 12),
    );
  }

  @override
  Future<LatLng> toLatLng(math.Point screenLocation) async {
    projectedPoints.add(screenLocation);
    final x = screenLocation.x / (viewportSize.width * projectionScale);
    final y = screenLocation.y / (viewportSize.height * projectionScale);
    final coordinates = LatLng(
      north - (north - south) * y,
      west + (east - west) * x,
    );
    await projectionBarrier;
    return coordinates;
  }
}

class _MapRoute extends MaterialPageRoute<void> {
  _MapRoute() : super(builder: (_) => const MemoriesMapView());

  void reverse() => controller!.reverse();
  void forward() => controller!.forward();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadMemoryMapCountries);
  late TwonlyDB database;
  late _MapPlatform platform;
  late Directory support;

  setUp(() async {
    database = TwonlyDB(NativeDatabase.memory());
    locator.registerSingleton<TwonlyDB>(database);
    platform = _MapPlatform();
    final originalFactory = MapLibrePlatform.createInstance;
    MapLibrePlatform.createInstance = () => platform;
    addTearDown(() => MapLibrePlatform.createInstance = originalFactory);
    support = Directory.systemTemp.createTempSync('memory-map-test-');
    AppEnvironment.supportDir = support.path;
    await database.customStatement(
      "INSERT INTO media_files(media_id, type, stored, has_thumbnail, location_latitude, location_longitude) VALUES('berlin', 'image', 1, 1, 52, 13), ('new-york', 'image', 1, 1, 40.7, -74)",
    );
    for (final file
        in await database.mediaFilesDao.watchGeotaggedMemories().first) {
      MediaFileService(file).thumbnailPath.writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
    }
  });

  tearDown(() async {
    await locator.unregister<TwonlyDB>();
    await database.close();
    support.deleteSync(recursive: true);
  });

  Widget app({
    ThemeMode mode = ThemeMode.light,
    MediaFile? initialMedia,
    Widget? home,
    GlobalKey<NavigatorState>? navigatorKey,
  }) => MaterialApp(
    navigatorKey: navigatorKey,
    theme: lightTheme,
    darkTheme: darkTheme,
    themeMode: mode,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home ?? MemoriesMapView(initialMedia: initialMedia),
  );

  Future<void> finishLoading(WidgetTester tester) async {
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump();
    platform.onMapStyleLoadedPlatform.call(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
  }

  Future<void> load(WidgetTester tester, {MediaFile? initialMedia}) async {
    await tester.pumpWidget(app(initialMedia: initialMedia));
    await finishLoading(tester);
  }

  testWidgets('map fills the screen with a back button below the status bar', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 44, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await load(tester);
    expect(find.byType(AppBar), findsNothing);
    expect(platform.viewportSize, const Size(400, 800));
    expect(tester.getTopLeft(find.byType(MapLibreMap)), Offset.zero);
    expect(
      tester.getTopLeft(find.byType(BackButton)).dy,
      greaterThanOrEqualTo(44),
    );
    final map = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
    expect(map.attributionButtonMargins!.y, 60);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'pauses before closing animation and resumes when back is cancelled',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        app(navigatorKey: navigator, home: const Scaffold()),
      );
      final route = _MapRoute();
      final closed = navigator.currentState!.push(route);
      await tester.pump();
      await finishLoading(tester);
      await tester.pumpAndSettle();

      route.reverse();
      expect(platform.renderingPaused.last, isTrue);
      // A gesture cancelled before it moves can jump straight to completed.
      route.forward();
      expect(platform.renderingPaused.last, isFalse);

      route.reverse();
      expect(platform.renderingPaused.last, isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(MapLibreMap), findsOneWidget);
      route.forward();
      expect(platform.renderingPaused.last, isFalse);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      expect(platform.renderingPaused.last, isTrue);
      expect(find.byType(MapLibreMap), findsOneWidget);
      await tester.pumpAndSettle();
      await closed;
      expect(find.byType(MapLibreMap), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    'loads both data sources and filters original photos when clustered',
    (tester) async {
      await load(tester);
      expect(platform.sources['memory-clusters']!['cluster'], isTrue);
      expect(
        platform.layers,
        containsAll([
          'memory-heatmap',
          'memory-cluster-counts',
          'memory-markers',
        ]),
      );
      final gallery = tester.widget<MemoriesMapGallery>(
        find.byType(MemoriesMapGallery),
      );
      expect(gallery.items.map((i) => i.mediaService.mediaFile.mediaId), [
        'berlin',
      ]);
      expect(platform.padding, hasLength(1));
      platform
        ..west = -75
        ..east = -73
        ..north = 42
        ..south = 39;
      platform.onCameraIdlePlatform.call(
        const CameraPosition(target: LatLng(40.7, -74), zoom: 12),
      );
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(
        tester
            .widget<MemoriesMapGallery>(find.byType(MemoriesMapGallery))
            .items
            .map((item) => item.mediaService.mediaFile.mediaId),
        ['new-york'],
      );
      expect(platform.padding, hasLength(1));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('theme changes restore layers while retaining the camera', (
    tester,
  ) async {
    await load(tester);
    platform.onCameraMovePlatform.call(
      const CameraPosition(target: LatLng(52.5, 13.4), zoom: 11),
    );
    await tester.pumpWidget(app(mode: ThemeMode.dark));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(platform.styles, [
      'https://tiles.openfreemap.org/styles/positron',
      'https://tiles.openfreemap.org/styles/fiord',
    ]);
    expect(platform.sources, hasLength(2));
    expect(platform.layers, hasLength(4));
    final map = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
    expect(map.initialCameraPosition!.target, const LatLng(52.5, 13.4));
    expect(map.initialCameraPosition!.zoom, 11);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('starts by framing the country with the most memories', (
    tester,
  ) async {
    await database.customStatement(
      "INSERT INTO media_files(media_id, type, stored, location_latitude, location_longitude) VALUES('hamburg', 'image', 1, 53.5511, 9.9937), ('munich', 'image', 1, 48.1351, 11.582)",
    );
    await load(tester);
    final map = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
    expect(map.initialCameraPosition!.target.longitude, closeTo(10.437, 0.01));
    expect(map.initialCameraPosition!.zoom, inInclusiveRange(3, 6));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('opening an image location centers the map on that image', (
    tester,
  ) async {
    final media = await database.mediaFilesDao.getMediaFileById('new-york');
    await load(tester, initialMedia: media);
    final map = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
    expect(map.initialCameraPosition!.target, const LatLng(40.7, -74));
    expect(map.initialCameraPosition!.zoom, 14);
    final locations =
        platform.sources['memory-locations']!['data'] as Map<String, Object?>;
    expect(locations['features'], hasLength(2));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  for (final target in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      '${target.name} locks gallery photos while expanding on high-density screens',
      (tester) async {
        tester.view
          ..physicalSize = const Size(1200, 2400)
          ..devicePixelRatio = 3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        platform.projectionScale = target == TargetPlatform.android ? 3 : 1;

        await load(tester);

        final gallery = tester.widget<MemoriesMapGallery>(
          find.byType(MemoriesMapGallery),
        );
        expect(
          gallery.items.map((item) => item.mediaService.mediaFile.mediaId),
          ['berlin'],
        );
        final bottomRight = platform.projectedPoints.last;
        expect(
          bottomRight.x,
          platform.viewportSize.width * platform.projectionScale,
        );
        expect(
          bottomRight.y,
          closeTo(
            platform.viewportSize.height *
                (1 - MemoriesMapGallery.initialSize) *
                platform.projectionScale,
            0.001,
          ),
        );

        // Start a viewport update that will finish after the gallery expands.
        final pendingProjection = Completer<void>();
        platform
          ..projectionBarrier = pendingProjection.future
          ..west = -75
          ..east = -73
          ..north = 42
          ..south = 39;
        platform.onCameraIdlePlatform.call(
          const CameraPosition(target: LatLng(40.7, -74), zoom: 12),
        );
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
        final projectionCount = platform.projectedPoints.length;

        gallery.controller.jumpTo(0.60);
        pendingProjection.complete();
        platform.projectionBarrier = null;
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
        expect(platform.projectedPoints, hasLength(projectionCount));
        expect(
          platform.padding.last.bottom,
          closeTo(platform.viewportSize.height * 0.60, 0.001),
        );
        expect(
          tester
              .widget<MemoriesMapGallery>(find.byType(MemoriesMapGallery))
              .items
              .map((item) => item.mediaService.mediaFile.mediaId),
          ['berlin'],
        );

        // Camera events caused by the new map padding must not replace the
        // photos being browsed, even if the visible map has moved elsewhere.
        platform.onCameraIdlePlatform.call(
          const CameraPosition(target: LatLng(40.7, -74), zoom: 12),
        );
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
        expect(
          tester
              .widget<MemoriesMapGallery>(find.byType(MemoriesMapGallery))
              .items
              .map((item) => item.mediaService.mediaFile.mediaId),
          ['berlin'],
        );

        // Reducing the gallery resumes filtering using the current map area.
        gallery.controller.jumpTo(0.50);
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
        expect(
          platform.projectedPoints.last.y,
          closeTo(
            platform.viewportSize.height * 0.50 * platform.projectionScale,
            0.001,
          ),
        );
        expect(
          tester
              .widget<MemoriesMapGallery>(find.byType(MemoriesMapGallery))
              .items
              .map((item) => item.mediaService.mediaFile.mediaId),
          ['new-york'],
        );
        // Putting the panel down leaves filtering active, including when it
        // snaps upward from the collapsed position to its normal height.
        gallery.controller.jumpTo(0.86);
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
        gallery.controller.jumpTo(0.16);
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
        platform
          ..west = 12
          ..east = 14
          ..north = 54
          ..south = 50;
        gallery.controller.jumpTo(MemoriesMapGallery.initialSize);
        platform.onCameraIdlePlatform.call(
          const CameraPosition(target: LatLng(52, 13), zoom: 12),
        );
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
        expect(
          tester
              .widget<MemoriesMapGallery>(find.byType(MemoriesMapGallery))
              .items
              .map((item) => item.mediaService.mediaFile.mediaId),
          ['berlin'],
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
      variant: TargetPlatformVariant({target}),
    );
  }
}
