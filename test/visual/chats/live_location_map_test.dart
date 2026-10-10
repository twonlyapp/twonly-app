import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/visual/components/location_map.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/chat_list_entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_live_location.entry.dart';

class _MapPlatform extends MapLibrePlatform {
  final renderingPaused = <bool>[];
  final cameraUpdates = <CameraUpdate>[];
  final points = <Map<String, dynamic>>[];
  bool created = false;

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
    return const SizedBox.expand();
  }

  @override
  Future<void> initPlatform(int id) async {}

  @override
  Future<void> pauseMap() async => renderingPaused.add(true);

  @override
  Future<void> resumeMap() async => renderingPaused.add(false);

  @override
  Future<CameraPosition?> updateMapOptions(
    Map<String, dynamic> updates,
  ) async => null;

  @override
  Future<void> addGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson, {
    String? promoteId,
  }) async {}

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
      points.add(data);

  @override
  Future<bool?> moveCamera(CameraUpdate cameraUpdate) async {
    cameraUpdates.add(cameraUpdate);
    return true;
  }
}

class _MapRoute extends MaterialPageRoute<void> {
  _MapRoute({
    required bool interactive,
    required ValueNotifier<double> latitude,
  }) : super(
         builder: (_) => Scaffold(
           appBar: AppBar(),
           body: ValueListenableBuilder<double>(
             valueListenable: latitude,
             builder: (_, value, _) => LocationMap(
               latitude: value,
               longitude: 13,
               interactive: interactive,
             ),
           ),
         ),
       );

  void reverse() => controller!.reverse();
  void forward() => controller!.forward();
}

class _ChatPreviewRoute extends MaterialPageRoute<void> {
  _ChatPreviewRoute()
    : super(
        builder: (_) => Scaffold(
          appBar: AppBar(),
          body: ListView(
            children: [
              for (final id in ['first', 'second'])
                ChatListEntry(
                  key: ValueKey(id),
                  group: _group(),
                  message: _message(id, location: true),
                  useSharedData: true,
                  hideReactions: true,
                ),
            ],
          ),
        ),
      );

  void reverse() => controller!.reverse();
  void forward() => controller!.forward();
}

Message _message(String id, {int? senderId, bool location = false}) => Message(
  groupId: 'group',
  messageId: id,
  senderId: senderId,
  type: 'text',
  content: 'Call',
  additionalMessageData: location
      ? AdditionalMessageData(
          type: AdditionalMessageData_Type.LIVE_LOCATION,
          liveLocation: LiveLocationData(
            sessionId: 'session',
            messageId: id,
            expiresAtMs: Int64(DateTime.now().millisecondsSinceEpoch + 60000),
            latitude: 52,
            longitude: 13,
          ),
        ).writeToBuffer()
      : null,
  mediaStored: false,
  mediaReopened: false,
  isDeletedFromSender: false,
  isWidgetMedia: false,
  isStory: false,
  createdAt: DateTime(2026),
);

Group _group() => Group(
  groupId: 'group',
  isGroupAdmin: true,
  isDirectChat: true,
  pinned: false,
  archived: false,
  joinedGroup: true,
  leftGroup: false,
  deletedContent: false,
  stateVersionId: 0,
  groupName: 'Test',
  totalMediaCounter: 0,
  alsoBestFriend: false,
  deleteMessagesAfterMilliseconds: 0,
  createdAt: DateTime(2026),
  flameCounter: 0,
  maxFlameCounter: 0,
  lastMessageExchange: DateTime(2026),
);

Widget _app({required Widget home, GlobalKey<NavigatorState>? navigator}) =>
    MaterialApp(
      navigatorKey: navigator,
      theme: lightTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  late _MapPlatform platform;

  setUp(() {
    platform = _MapPlatform();
    final original = MapLibrePlatform.createInstance;
    MapLibrePlatform.createInstance = () => platform;
    addTearDown(() => MapLibrePlatform.createInstance = original);
  });

  Future<void> finishLoading(WidgetTester tester) async {
    await tester.pump();
    platform.onMapStyleLoadedPlatform.call(null);
    await tester.pumpAndSettle();
    expect(platform.cameraUpdates, hasLength(1));
  }

  for (final sender in [null, 42]) {
    testWidgets(
      'location corners follow neighboring messages (sender $sender)',
      (
        tester,
      ) async {
        final message = _message('location', senderId: sender, location: true);
        final previous = _message('previous', senderId: sender);
        final next = _message('next', senderId: sender);

        Future<void> show({Message? before, Message? after}) =>
            tester.pumpWidget(
              _app(
                home: Scaffold(
                  body: ChatListEntry(
                    group: _group(),
                    message: message,
                    prevMessage: before,
                    nextMessage: after,
                    useSharedData: true,
                    hideReactions: true,
                  ),
                ),
              ),
            );

        BorderRadiusGeometry corners() => tester
            .widget<ClipRRect>(
              find
                  .descendant(
                    of: find.byType(ChatLiveLocationEntry),
                    matching: find.byType(ClipRRect),
                  )
                  .first,
            )
            .borderRadius;

        await show();
        await finishLoading(tester);
        expect(corners(), BorderRadius.circular(12));
        await show(after: next);
        expect(
          corners(),
          BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(sender == null ? 12 : 5),
            bottomRight: Radius.circular(sender == null ? 5 : 12),
          ),
        );
        await show(before: previous, after: next);
        expect(
          corners(),
          BorderRadius.only(
            topLeft: Radius.circular(sender == null ? 12 : 5),
            topRight: Radius.circular(sender == null ? 5 : 12),
            bottomLeft: Radius.circular(sender == null ? 12 : 5),
            bottomRight: Radius.circular(sender == null ? 5 : 12),
          ),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final interactive in [false, true]) {
    testWidgets(
      'map (interactive $interactive) pauses before back and catches up after cancellation',
      (tester) async {
        final navigator = GlobalKey<NavigatorState>();
        final latitude = ValueNotifier<double>(52);
        addTearDown(latitude.dispose);
        await tester.pumpWidget(
          _app(home: const Scaffold(), navigator: navigator),
        );
        final route = _MapRoute(interactive: interactive, latitude: latitude);
        final closed = navigator.currentState!.push(route);
        await tester.pump();
        await finishLoading(tester);

        route.reverse();
        expect(platform.renderingPaused.last, isTrue);
        // A canceled gesture without movement jumps directly to completed.
        route.forward();
        expect(platform.renderingPaused.last, isFalse);
        await tester.pumpAndSettle();

        route.reverse();
        expect(platform.renderingPaused.last, isTrue);
        final updatesBeforeClosing = platform.cameraUpdates.length;
        final pointsBeforeClosing = platform.points.length;
        latitude.value = 53;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(
          find.byType(MapLibreMap),
          interactive ? findsOneWidget : findsNothing,
        );
        expect(find.byType(MapLibreMap, skipOffstage: false), findsOneWidget);
        expect(platform.cameraUpdates, hasLength(updatesBeforeClosing));
        expect(platform.points, hasLength(pointsBeforeClosing));
        route.forward();
        expect(platform.renderingPaused.last, isFalse);
        await tester.pumpAndSettle();
        expect(platform.cameraUpdates, hasLength(updatesBeforeClosing + 1));
        final features = platform.points.last['features'] as List;
        final point = features.single as Map;
        expect((point['geometry'] as Map)['coordinates'], [13, 53]);

        await tester.tap(find.byType(BackButton));
        expect(platform.renderingPaused.last, isTrue);
        expect(find.byType(MapLibreMap), findsOneWidget);
        await tester.pumpAndSettle();
        await closed;
        expect(find.byType(MapLibreMap), findsNothing);
        expect(tester.takeException(), isNull);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );
  }

  for (final systemBack in [false, true]) {
    testWidgets(
      'inline chat maps disappear on ${systemBack ? 'system' : 'app-bar'} back and restore on cancellation',
      (tester) async {
        final maps = <_MapPlatform>[];
        MapLibrePlatform.createInstance = () {
          final map = _MapPlatform();
          maps.add(map);
          return map;
        };
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          _app(home: const Scaffold(), navigator: navigator),
        );
        final route = _ChatPreviewRoute();
        final closed = navigator.currentState!.push(route);
        await tester.pump();
        await tester.pump();
        expect(maps, hasLength(2));
        for (final map in maps) {
          map.onMapStyleLoadedPlatform.call(null);
        }
        await tester.pumpAndSettle();
        final bubbleSize = tester.getSize(
          find.byType(ChatLiveLocationEntry).first,
        );

        route.reverse();
        expect(maps.every((map) => map.renderingPaused.last), isTrue);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(MapLibreMap), findsNothing);
        expect(find.byType(MapLibreMap, skipOffstage: false), findsNWidgets(2));
        expect(find.byType(ChatLiveLocationEntry), findsNWidgets(2));
        expect(
          tester.getSize(find.byType(ChatLiveLocationEntry).first),
          bubbleSize,
        );

        route.forward();
        expect(maps.every((map) => !map.renderingPaused.last), isTrue);
        await tester.pumpAndSettle();
        expect(find.byType(MapLibreMap), findsNWidgets(2));
        // Restoring a canceled back gesture must keep the existing native maps.
        expect(maps, hasLength(2));

        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.byType(BackButton));
        }
        expect(maps.every((map) => map.renderingPaused.last), isTrue);
        await tester.pump();
        expect(find.byType(MapLibreMap), findsNothing);
        expect(find.byType(ChatLiveLocationEntry), findsNWidgets(2));
        await tester.pumpAndSettle();
        await closed;
        expect(find.byType(MapLibreMap, skipOffstage: false), findsNothing);
        expect(tester.takeException(), isNull);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );
  }

  testWidgets('system back pauses the native map before route disposal', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    final latitude = ValueNotifier<double>(52);
    addTearDown(latitude.dispose);
    await tester.pumpWidget(_app(home: const Scaffold(), navigator: navigator));
    final closed = navigator.currentState!.push(
      _MapRoute(interactive: true, latitude: latitude),
    );
    await tester.pump();
    await finishLoading(tester);
    await tester.binding.handlePopRoute();
    expect(platform.renderingPaused.last, isTrue);
    expect(find.byType(MapLibreMap), findsOneWidget);
    await tester.pumpAndSettle();
    await closed;
    expect(find.byType(MapLibreMap), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
