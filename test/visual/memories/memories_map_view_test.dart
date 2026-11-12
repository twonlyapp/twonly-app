import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart'
    as db_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/helpers/memory_map_countries.helper.dart';
import 'package:twonly/src/visual/themes/dark.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/memories/components/memories_map_gallery.comp.dart';
import 'package:twonly/src/visual/views/memories/memories_map.view.dart';

import '../../helpers/native_database.dart';

class _MapPlatform extends MapLibrePlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected map call: ${invocation.memberName}');

  final sources = <String, Map<String, dynamic>>{};
  final layers = <String>{};
  final images = <String>{};
  final imageBytes = <String, Uint8List>{};
  final symbols = <String, Map<String, dynamic>>{};
  final symbolSources = <String, String>{};
  List<Map<String, dynamic>> tapFeatures = [];
  final queriedLayers = <List<String>>[];
  final expandedClusters = <(String, int)>[];
  final cameraAnimations = <CameraUpdate>[];
  final imagesAtLayerCreation = <String, Set<String>>{};
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
      symbols.clear();
      symbolSources.clear();
      images.clear();
      imageBytes.clear();
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
  Future<void> removeLayer(String id) async {
    layers.remove(id);
    symbols.remove(id);
    symbolSources.remove(id);
  }

  @override
  Future<void> addHeatmapLayer(
    String sourceId,
    String layerId,
    Map<String, dynamic> properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
  }) async {
    layers.add(layerId);
  }

  @override
  Future<void> addImage(
    String name,
    Uint8List bytes, [
    bool sdf = false,
  ]) async {
    images.add(name);
    imageBytes[name] = bytes;
  }

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
  }) async {
    layers.add(layerId);
    symbols[layerId] = properties;
    symbolSources[layerId] = sourceId;
    imagesAtLayerCreation[layerId] = Set.of(images);
  }

  @override
  Future<List<dynamic>> queryRenderedFeaturesInRect(
    Rect rect,
    List<String> layerIds,
    String? filter,
  ) async {
    queriedLayers.add(layerIds);
    return tapFeatures;
  }

  @override
  Future<int> getClusterExpansionZoom(String sourceId, int clusterId) async {
    expandedClusters.add((sourceId, clusterId));
    return 15;
  }

  @override
  Future<bool?> animateCamera(
    CameraUpdate cameraUpdate, {
    Duration? duration,
  }) async {
    cameraAnimations.add(cameraUpdate);
    return true;
  }

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
  late TestDatabase database;
  late _MapPlatform platform;
  late Directory support;

  setUp(() async {
    database = await TestDatabase.create();

    platform = _MapPlatform();
    final originalFactory = MapLibrePlatform.createInstance;
    MapLibrePlatform.createInstance = () => platform;
    addTearDown(() => MapLibrePlatform.createInstance = originalFactory);
    support = Directory.systemTemp.createTempSync('memory-map-test-');
    AppEnvironment.supportDir = support.path;
    await database.customStatement(
      "INSERT INTO media_files(media_id, type, stored, has_thumbnail, location_latitude, location_longitude) VALUES('berlin', 'image', 1, 1, 52, 13), ('new-york', 'image', 1, 1, 40.7, -74)",
    );
    for (final file in await watchRustDatabase(
      (control) => rust_mediafiles
          .watchMediaFiles(
            input: const db_mediafiles.MediaQuery(
              filter: db_mediafiles.MediaFilter.geotagged,
            ),
            control: control,
          )
          .map(orderedMediaFiles),
    ).first) {
      MediaFileService(file).thumbnailPath.writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
    }
  });

  tearDown(() async {
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

  MemoryItem storyItem(MediaFile file, int senderId) => MemoryItem(
    mediaService: MediaFileService(file),
    messages: [
      StoredMessage(
        groupId: 'chat',
        messageId: 'story',
        senderId: senderId,
        type: 'media',
        mediaId: file.mediaId,
        additionalMessageData: AdditionalMessageData(
          photoLocation: PhotoLocationData(latitude: 52, longitude: 13),
        ).writeToBuffer(),
        mediaStored: false,
        mediaReopened: false,
        isDeletedFromSender: false,
        isWidgetMedia: false,
        isStory: true,
        createdAtSeconds: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    ],
  );

  testWidgets(
    'story map uses shared coordinates, avatars and the same gallery',
    (tester) async {
      // Above the exact integer range of native GeoJSON's double values.
      final senderId = int.parse('9007199254740993');
      const avatarKey = 'story-avatar-9007199254740993';
      final sourceId = 'story-locations-$senderId';
      final clusterLayer = 'memory-cluster-circles-$senderId';
      final markerLayer = 'memory-markers-$senderId';
      final stream = StreamController<List<MemoryItem>>.broadcast();
      final file = await runNative(
        tester,
        () => rust_mediafiles.getMediaFile(
          id: 'new-york',
          transaction: currentDatabaseSession(),
        ),
      );
      final item = storyItem(file!, senderId);
      List<MemoryItem>? opened;
      await tester.pumpWidget(
        app(
          home: MemoriesMapView.stories(
            storyItems: stream.stream,
            onOpenStories: (items, index) async => opened = items,
          ),
        ),
      );
      stream.add([item]);
      await tester.pump();
      await finishLoading(tester);
      await pumpNative(
        tester,
        until: () =>
            platform.images.contains(avatarKey) &&
            platform.layers.contains(markerLayer),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(platform.layers, isNot(contains('memory-heatmap')));
      expect(platform.layers, isNot(contains('memory-cluster-counts')));
      expect(platform.symbols[markerLayer]!['icon-size'], 0.55);
      expect(platform.symbols[clusterLayer]!['icon-size'], [
        'interpolate',
        ['linear'],
        ['get', 'point_count'],
        2,
        0.6,
        20,
        0.65,
      ]);
      for (final layer in [markerLayer, clusterLayer]) {
        expect(
          platform.imagesAtLayerCreation[layer],
          contains(avatarKey),
          reason:
              'Native symbol layout needs the bitmap before layer creation.',
        );
        expect(
          platform.symbols[layer]!['text-font'],
          ['Noto Sans Regular'],
          reason: 'Avatar symbols need the font supported by the map style.',
        );
      }
      final pixels = await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(
          platform.imageBytes[avatarKey]!,
        );
        final frame = await codec.getNextFrame();
        codec.dispose();
        final data = await frame.image.toByteData();
        frame.image.dispose();
        return data!.buffer.asUint8List();
      });
      var hasAvatar = false;
      for (var offset = 0; offset < pixels!.length; offset += 4) {
        // A contact without a custom avatar still gets the green default
        // silhouette, instead of an empty blue marker.
        if (pixels[offset + 3] > 0 &&
            pixels[offset + 1] > pixels[offset] &&
            pixels[offset + 1] > pixels[offset + 2]) {
          hasAvatar = true;
        }
      }
      expect(hasAvatar, isTrue);
      expect(
        pixels[(2 * 96 + 48) * 4 + 3],
        0,
        reason: 'Avatar markers have no painted background or border.',
      );
      for (final layer in [markerLayer, clusterLayer]) {
        expect(platform.symbols[layer]!['icon-image'], avatarKey);
        expect(platform.symbolSources[layer], sourceId);
      }
      final data = platform.sources[sourceId]!['data'] as Map;
      final point = (data['features'] as List).single as Map;
      expect((point['geometry'] as Map)['coordinates'], [13, 52]);
      expect((point['properties'] as Map)['avatar'], avatarKey);
      expect(platform.sources[sourceId]!['clusterProperties'], {
        'storySource': [
          [
            'coalesce',
            ['accumulated'],
            ['get', 'storySource'],
          ],
          ['literal', sourceId],
        ],
      });
      final gallery = tester.widget<MemoriesMapGallery>(
        find.byType(MemoriesMapGallery),
      );
      expect(gallery.stories, isTrue);
      expect(
        tester
            .element(find.byType(BackButton))
            .findAncestorWidgetOfExactType<Material>()!
            .elevation,
        0,
      );
      expect(
        tester
            .widget<Material>(
              find
                  .descendant(
                    of: find.byType(MemoriesMapGallery),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .elevation,
        0,
      );
      expect(gallery.items, [item]);
      gallery.onTap(0);
      await tester.pump();
      expect(opened, [item]);
      await tester.pumpWidget(const SizedBox());
      await stream.close();
    },
  );

  testWidgets(
    'story clusters keep authors separate at the same coordinates and across updates',
    (tester) async {
      await runNative(
        tester,
        () => database.customStatement(
          "INSERT INTO media_files(media_id, type, stored, has_thumbnail) VALUES('third-story', 'image', 1, 1)",
        ),
      );
      final files = await runNative(
        tester,
        () => Future.wait([
          for (final id in ['berlin', 'new-york', 'third-story'])
            rust_mediafiles.getMediaFile(
              id: id,
              transaction: currentDatabaseSession(),
            ),
        ]),
      );
      final items = [
        storyItem(files[0]!, 7),
        storyItem(files[1]!, 8),
        storyItem(files[2]!, 7),
      ];
      final stream = StreamController<List<MemoryItem>>.broadcast();
      final home = MemoriesMapView.stories(
        storyItems: stream.stream,
        onOpenStories: (_, _) async {},
      );
      await tester.pumpWidget(app(home: home));
      stream.add(items);
      await tester.pump();
      await finishLoading(tester);
      await pumpNative(
        tester,
        until: () => platform.layers.contains('memory-markers-8'),
      );

      List<Map<String, dynamic>> features(String source) =>
          ((platform.sources[source]!['data'] as Map)['features']
                  as List<dynamic>)
              .cast<Map<String, dynamic>>();
      expect(platform.sources.containsKey('memory-clusters'), isFalse);
      expect(features('story-locations-7'), hasLength(2));
      expect(features('story-locations-8'), hasLength(1));
      for (final sender in [7, 8]) {
        for (final point in features('story-locations-$sender')) {
          expect((point['geometry'] as Map)['coordinates'], [13, 52]);
          expect(
            (point['properties'] as Map)['avatar'],
            'story-avatar-$sender',
          );
        }
        expect(
          platform.symbolSources['memory-cluster-circles-$sender'],
          'story-locations-$sender',
        );
        expect(
          platform.symbols['memory-cluster-circles-$sender']!['icon-image'],
          'story-avatar-$sender',
        );
      }
      expect(
        platform.symbols.values.every(
          (symbol) => !symbol.containsKey('text-field'),
        ),
        isTrue,
      );

      // Native cluster IDs can coincide across sources. Zoom the tapped author's
      // source, rather than another person's identically numbered cluster.
      for (final sender in [8, 7]) {
        platform.tapFeatures = [
          {
            'type': 'Feature',
            'properties': {
              'cluster_id': 42,
              'storySource': 'story-locations-$sender',
            },
            'geometry': {
              'type': 'Point',
              'coordinates': [13, 52],
            },
          },
        ];
        final before = platform.cameraAnimations.length;
        platform.onMapClickPlatform.call({
          'point': const math.Point<double>(100, 100),
          'latLng': const LatLng(52, 13),
        });
        await pumpNative(
          tester,
          until: () => platform.cameraAnimations.length > before,
        );
        expect(platform.expandedClusters.last, ('story-locations-$sender', 42));
      }
      expect(
        platform.queriedLayers.last,
        containsAll([
          'memory-cluster-circles-7',
          'memory-markers-7',
          'memory-cluster-circles-8',
          'memory-markers-8',
        ]),
      );

      stream.add([items.last]);
      await pumpNative(
        tester,
        until: () =>
            !platform.sources.containsKey('story-locations-8') &&
            features('story-locations-7').length == 1,
      );
      expect(platform.layers.contains('memory-markers-8'), isFalse);
      expect(platform.layers.contains('memory-cluster-circles-8'), isFalse);

      await tester.pumpWidget(app(mode: ThemeMode.dark, home: home));
      await pumpNative(
        tester,
        until: () =>
            platform.layers.contains('memory-markers-7') &&
            platform.images.contains('story-avatar-7'),
      );
      expect(features('story-locations-7'), hasLength(1));
      expect(platform.sources.containsKey('story-locations-8'), isFalse);
      expect(
        platform.imagesAtLayerCreation['memory-markers-7'],
        contains('story-avatar-7'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await stream.close();
    },
  );

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
    await runNative(
      tester,
      () => database.customStatement(
        "INSERT INTO media_files(media_id, type, stored, location_latitude, location_longitude) VALUES('hamburg', 'image', 1, 53.5511, 9.9937), ('munich', 'image', 1, 48.1351, 11.582)",
      ),
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
    final media = await runNative(
      tester,
      () => rust_mediafiles.getMediaFile(
        id: 'new-york',
        transaction: currentDatabaseSession(),
      ),
    );
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
