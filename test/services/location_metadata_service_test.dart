import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/location_metadata.service.dart';
import 'package:twonly/src/services/user.service.dart';

import '../mocks/user_config.dart';

class _LocationApi implements RustLibApi {
  int warmups = 0;

  @override
  Future<void> crateBridgeApiRustApiPrewarmMemoryLocation() async => warmups++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('eu.twonly/location_metadata');
  final api = _LocationApi();
  var permission = true;
  final calls = <MethodCall>[];

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
    api.warmups = 0;
    permission = true;
    calls.clear();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      switch (call.method) {
        case 'hasPrecisePermission':
        case 'requestPrecisePermission':
          return permission;
      }
      throw MissingPluginException(call.method);
    });
  });

  tearDown(() async {
    LocationMetadataService.dispose();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await locator.reset();
  });

  Future<void> flush() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('default-disabled startup does not touch native location', () async {
    LocationMetadataService.initialize();
    await flush();
    expect(calls, isEmpty);
    expect(api.warmups, 0);
  });

  test('Memories warm up coordinates without a permission prompt', () async {
    userService.currentUser.storeLocationInMemories = true;
    LocationMetadataService.initialize();
    await flush();
    expect(api.warmups, 1);
    expect(calls.map((call) => call.method), ['hasPrecisePermission']);
  });

  test('permission denial on startup does not acquire a location', () async {
    userService.currentUser.storeLocationInMemories = true;
    permission = false;
    LocationMetadataService.initialize();
    await flush();
    expect(api.warmups, 0);
    expect(calls.map((call) => call.method), ['hasPrecisePermission']);
  });

  test('enabling and foreground resume start location automatically', () async {
    LocationMetadataService.initialize();
    userService.currentUser.storeLocationInMemories = true;
    userService.triggerUserUpdate();
    await flush();
    expect(api.warmups, 1);
    binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await flush();
    expect(api.warmups, 2);
  });
}
