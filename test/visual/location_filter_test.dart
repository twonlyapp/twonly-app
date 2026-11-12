import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/components/location_card.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/filter.layer.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/photo_location_overlay.comp.dart';

import '../mocks/user_config.dart';

class _MapPlatform extends MapLibrePlatform {
  bool created = false;
  int pointerMoves = 0;
  final sources = <Map<String, dynamic>>[];
  final cameraUpdates = <CameraUpdate>[];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected map call: ${invocation.memberName}');

  @override
  Widget buildView(
    Map<String, dynamic> params,
    OnPlatformViewCreatedCallback onCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) {
    if (!created) {
      created = true;
      onCreated(0);
    }
    final surface = Listener(
      behavior: HitTestBehavior.opaque,
      onPointerMove: (_) => pointerMoves++,
      child: const SizedBox.expand(),
    );
    if (gestureRecognizers == null || gestureRecognizers.isEmpty) {
      return surface;
    }
    // Model the native surface claiming its configured map gestures before
    // the media viewer can treat them as taps to advance to the next image.
    return RawGestureDetector(
      gestures: {
        EagerGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
              EagerGestureRecognizer.new,
              (_) {},
            ),
      },
      child: surface,
    );
  }

  @override
  Future<void> initPlatform(int id) async {}

  @override
  Future<CameraPosition?> updateMapOptions(
    Map<String, dynamic> updates,
  ) async => null;

  @override
  Future<void> addGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson, {
    String? promoteId,
  }) async => sources.add(geojson);

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
  }) async {}

  @override
  Future<void> setGeoJsonSource(String id, Map<String, dynamic> data) async =>
      sources.add(data);

  @override
  Future<bool?> moveCamera(CameraUpdate update) async {
    cameraUpdates.add(update);
    return true;
  }
}

Widget _app(Widget child) => MaterialApp(
  theme: lightTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  late FilterLayerData data;
  late PageController pages;
  late ScreenshotController screenshot;
  late List<_MapPlatform> maps;
  const fix = FilterLocation(
    latitude: 52.52,
    longitude: 13.405,
    accuracy: 5,
    fixTimestampMs: 1,
  );
  const editedCamera = CameraPosition(target: LatLng(52.6, 13.5), zoom: 10);

  setUp(() async {
    await locator.reset();
    locator.registerSingleton<UserService>(UserService());
    userService.currentUser = testUserConfig(
      userId: 1,
      username: 'test',
      displayName: 'Test',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 1,
    )..locationFilter = true;
    AppEnvironment.cacheDir = '/tmp';
    data = FilterLayerData(key: GlobalKey())..page = 3;
    screenshot = ScreenshotController();
    maps = [];
    final original = MapLibrePlatform.createInstance;
    MapLibrePlatform.createInstance = () {
      final map = _MapPlatform();
      maps.add(map);
      return map;
    };
    addTearDown(() => MapLibrePlatform.createInstance = original);
    addTearDown(locator.reset);
    addTearDown(data.showLocationCard.dispose);
  });

  Future<void> finishMap(WidgetTester tester) async {
    await tester.pump();
    maps.last.onMapStyleLoadedPlatform.call(null);
    await tester.pumpAndSettle();
  }

  Future<void> showFilter(WidgetTester tester) async {
    data
      ..location = fix
      ..locationRequest = Future<FilterLocation?>.value(fix);
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 400,
          height: 600,
          child: Screenshot(
            controller: screenshot,
            child: FilterLayer(layerData: data),
          ),
        ),
      ),
    );
    await finishMap(tester);
    pages = tester.widget<PageView>(find.byType(PageView)).controller!;
  }

  testWidgets('map accepts pan and zoom while the card stays fixed', (
    tester,
  ) async {
    await showFilter(tester);
    final card = find.byKey(data.locationCardKey);
    final before = tester.getRect(card);
    final map = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
    expect(map.scrollGesturesEnabled, isTrue);
    expect(map.zoomGesturesEnabled, isTrue);
    expect(map.rotateGesturesEnabled, isFalse);
    expect(map.trackCameraPosition, isTrue);
    expect(
      map.attributionButtonPosition,
      AttributionButtonPosition.bottomRight,
    );
    expect(map.attributionButtonMargins, isNull);
    expect(
      map.gestureRecognizers!.single.constructor(),
      isA<EagerGestureRecognizer>(),
    );
    expect(find.byKey(const Key('locationCardResize')), findsNothing);

    await tester.drag(card, const Offset(30, -50));
    await tester.pumpAndSettle();
    expect(maps.single.pointerMoves, greaterThan(0));
    // Native camera events carry the result of map pan and pinch gestures.
    maps.single.onCameraMovePlatform.call(editedCamera);
    await tester.pump();
    expect(data.locationCamera, editedCamera);
    expect(tester.getRect(card), before);
    expect(pages.page, 3);
    const finalCamera = CameraPosition(target: LatLng(52.7, 13.6), zoom: 9);
    maps.single.onCameraIdlePlatform.call(finalCamera);
    expect(data.locationCamera, finalCamera);

    final feature =
        (maps.single.sources.single['features'] as List).single as Map;
    expect((feature['geometry'] as Map)['coordinates'], [
      fix.longitude,
      fix.latitude,
    ]);
  });

  testWidgets(
    'outside swipes change filter and returning restores the viewport',
    (
      tester,
    ) async {
      await showFilter(tester);
      maps.single.onCameraMovePlatform.call(editedCamera);
      final canvas = tester.getTopLeft(find.byType(Screenshot));
      await tester.dragFrom(
        canvas + const Offset(350, 100),
        const Offset(-350, 0),
      );
      await tester.pumpAndSettle();
      expect(pages.page, 4);
      expect(data.locationSelected, isFalse);

      pages.jumpToPage(3);
      await finishMap(tester);
      expect(data.locationSelected, isTrue);
      expect(
        tester
            .widget<MapLibreMap>(find.byType(MapLibreMap))
            .initialCameraPosition,
        editedCamera,
      );
      expect(data.locationCamera, editedCamera);
    },
  );

  testWidgets('capture hides the card and preserves its map selection', (
    tester,
  ) async {
    await showFilter(tester);
    maps.single.onCameraMovePlatform.call(editedCamera);
    final exported = screenshot.relativeRect(data.locationCardKey);
    data.showLocationCard.value = false;
    await tester.pump();
    expect(find.byType(LocationCard), findsNothing);
    expect(screenshot.relativeRect(data.locationCardKey), exported);
    expect(data.locationCamera, editedCamera);

    data.showLocationCard.value = true;
    await tester.pump();
    expect(find.byType(LocationCard), findsOneWidget);
    expect(screenshot.relativeRect(data.locationCardKey), exported);
    expect(data.locationCamera, editedCamera);
  });

  testWidgets(
    'recipient explores independently and each image starts at the sender view',
    (
      tester,
    ) async {
      final location = PhotoLocationData(
        latitude: fix.latitude,
        longitude: fix.longitude,
        mapLeft: 0.175,
        mapTop: 0.55,
        mapWidth: 0.65,
        mapHeight: 190 / 600,
        mapLatitude: editedCamera.target.latitude,
        mapLongitude: editedCamera.target.longitude,
        mapZoom: editedCamera.zoom,
      );
      final decoded = PhotoLocationOverlay.decode(
        AdditionalMessageData(photoLocation: location).writeToBuffer(),
      )!;
      final originalMetadata = decoded.writeToBuffer();
      var viewerTaps = 0;
      Widget viewer({String mediaId = 'first'}) => _app(
        GestureDetector(
          onTap: () => viewerTaps++,
          child: SizedBox(
            width: 400,
            height: 600,
            child: PhotoLocationOverlay(
              key: ValueKey(mediaId),
              location: PhotoLocationData.fromBuffer(originalMetadata),
              mediaAspectRatio: 400 / 600,
            ),
          ),
        ),
      );
      await tester.pumpWidget(viewer());
      await finishMap(tester);
      final map = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
      expect(map.initialCameraPosition, editedCamera);
      expect(map.scrollGesturesEnabled, isTrue);
      expect(map.zoomGesturesEnabled, isTrue);
      expect(map.trackCameraPosition, isTrue);
      await tester.tap(find.byType(LocationCard));
      await tester.drag(find.byType(LocationCard), const Offset(50, 0));
      await tester.pumpAndSettle();
      expect(maps.single.pointerMoves, greaterThan(0));
      expect(viewerTaps, 0);

      const recipientCamera = CameraPosition(
        target: LatLng(53, 14),
        zoom: 12,
      );
      maps.single.onCameraMovePlatform.call(recipientCamera);
      maps.single.onCameraIdlePlatform.call(recipientCamera);
      final updatesBeforeRebuild = maps.single.cameraUpdates.length;
      await tester.pumpWidget(viewer());
      await tester.pumpAndSettle();
      expect(maps, hasLength(1));
      expect(maps.single.cameraUpdates, hasLength(updatesBeforeRebuild));
      expect(
        tester
            .widget<MapLibreMap>(find.byType(MapLibreMap))
            .initialCameraPosition,
        recipientCamera,
      );
      expect(decoded.writeToBuffer(), originalMetadata);
      final feature =
          (maps.single.sources.single['features'] as List).single as Map;
      expect((feature['geometry'] as Map)['coordinates'], [
        fix.longitude,
        fix.latitude,
      ]);

      await tester.pumpWidget(viewer(mediaId: 'next'));
      await finishMap(tester);
      expect(maps, hasLength(2));
      expect(
        tester
            .widget<MapLibreMap>(find.byType(MapLibreMap))
            .initialCameraPosition,
        editedCamera,
      );
    },
  );
}
