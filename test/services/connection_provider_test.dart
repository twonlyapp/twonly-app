import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/services/api/api.service.dart';

class _ConnectionApi implements RustLibApi {
  late StreamController<ApiEvent> events;
  late Completer<ApiConnectionState> initialState;

  @override
  Stream<ApiEvent> crateBridgeApiRustApiEvents() => events.stream;

  @override
  Future<ApiConnectionState> crateBridgeApiRustApiConnectionState() =>
      initialState.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _ConnectionApi();
  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    await locator.reset();
    api
      ..events = StreamController<ApiEvent>.broadcast(sync: true)
      ..initialState = Completer<ApiConnectionState>();
    locator.registerSingleton<ApiService>(ApiService());
  });

  tearDown(() async {
    await apiService.dispose();
    await api.events.close();
    await locator.reset();
  });

  void emit(ApiConnectionState state) => api.events.add(
    ApiEvent(
      kind: ApiEventKind.connectionStateChanged,
      state: state,
    ),
  );

  test(
    'late initial query cannot overwrite a newer authenticated event',
    () async {
      final provider = CustomChangeProvider();
      addTearDown(provider.dispose);
      emit(ApiConnectionState.authenticated);
      expect(provider.isConnected, isTrue);
      api.initialState.complete(ApiConnectionState.stopped);
      await Future<void>.delayed(Duration.zero);
      expect(provider.isConnected, isTrue);
    },
  );

  test('late query cannot overwrite a newer disconnection', () async {
    final provider = CustomChangeProvider();
    addTearDown(provider.dispose);
    emit(ApiConnectionState.stopped);
    api.initialState.complete(ApiConnectionState.authenticated);
    await Future<void>.delayed(Duration.zero);
    expect(provider.isConnected, isFalse);
  });

  test('suspension retains the last transport state', () async {
    final provider = CustomChangeProvider();
    addTearDown(provider.dispose);
    api.initialState.complete(ApiConnectionState.authenticated);
    await Future<void>.delayed(Duration.zero);
    emit(ApiConnectionState.suspended);
    expect(provider.isConnected, isTrue);
    emit(ApiConnectionState.stopped);
    expect(provider.isConnected, isFalse);
  });

  test(
    'finishing initial query after disposal does not notify listeners',
    () async {
      final provider = CustomChangeProvider();
      var notifications = 0;
      provider
        ..addListener(() => notifications++)
        ..dispose();
      api.initialState.complete(ApiConnectionState.authenticated);
      await Future<void>.delayed(Duration.zero);
      expect(notifications, 0);
    },
  );
}
