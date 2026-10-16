import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/android_camera_volume_control.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const events = MethodChannel('dart-tools.dev/flutter_android_volume_keydown');
  late AndroidCameraVolumeControl control;
  late List<String> calls;
  late List<FlutterErrorDetails> flutterErrors;
  FlutterExceptionHandler? previousErrorHandler;
  late int pictures;
  var missingRegistration = false;
  var missingCleanup = false;
  var failedRegistration = false;
  var failedCleanup = false;
  Completer<void>? registration;

  setUp(() {
    calls = [];
    flutterErrors = [];
    previousErrorHandler = FlutterError.onError;
    FlutterError.onError = flutterErrors.add;
    pictures = 0;
    missingRegistration = false;
    missingCleanup = false;
    failedRegistration = false;
    failedCleanup = false;
    registration = null;
    control = AndroidCameraVolumeControl(onPressed: () async => pictures++);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(events, (
      call,
    ) async {
      calls.add(call.method);
      if (call.method == 'listen') {
        await registration?.future;
        if (missingRegistration) throw MissingPluginException();
        if (failedRegistration) throw PlatformException(code: 'unavailable');
      } else {
        if (missingCleanup) throw MissingPluginException();
        if (failedCleanup) throw PlatformException(code: 'cleanup');
      }
      return null;
    });
  });

  tearDown(() async {
    await control.stop();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(events, null);
    FlutterError.onError = previousErrorHandler;
    expect(flutterErrors, isEmpty);
  });

  Future<void> emit(bool down) async {
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      events.name,
      events.codec.encodeSuccessEnvelope(down),
      (_) {},
    );
  }

  test(
    'missing plugin during cancellation is contained and permits retry',
    () async {
      await control.start();
      missingCleanup = true;
      await control.stop();
      await control.stop();
      await emit(true);
      expect(pictures, 0);
      expect(calls, ['listen', 'cancel']);

      missingCleanup = false;
      await control.start();
      await emit(true);
      expect(pictures, 1);
    },
  );

  test(
    'missing registration and cleanup do not report Flutter errors',
    () async {
      missingRegistration = true;
      missingCleanup = true;
      await control.start();
      await emit(true);
      expect(pictures, 0);

      missingRegistration = false;
      missingCleanup = false;
      await control.start();
      await emit(false);
      expect(pictures, 1);
    },
  );

  test('both buttons take pictures without duplicate registration', () async {
    await control.start();
    await control.start();
    await emit(true);
    await emit(false);
    expect(pictures, 2);
    expect(calls, ['listen']);

    await control.stop();
    await emit(true);
    expect(pictures, 2);
  });

  test('stop during registration blocks events and cleans up once', () async {
    registration = Completer<void>();
    final starting = control.start();
    await Future<void>.delayed(Duration.zero);
    final stopping = control.stop();
    await emit(true);
    registration!.complete();
    await starting;
    await stopping;

    expect(pictures, 0);
    expect(calls, ['listen', 'cancel']);
  });

  test('restart waits for pending registration and cancellation', () async {
    registration = Completer<void>();
    final starting = control.start();
    await Future<void>.delayed(Duration.zero);
    final stopping = control.stop();
    final restarting = control.start();
    await emit(true);
    expect(pictures, 0);
    registration!.complete();
    await starting;
    await stopping;
    await restarting;

    expect(calls, ['listen', 'cancel', 'listen']);
    await emit(true);
    expect(pictures, 1);
  });

  test('platform registration and cleanup errors permit retry', () async {
    failedRegistration = true;
    failedCleanup = true;
    await control.start();
    await emit(true);
    expect(pictures, 0);

    failedRegistration = false;
    failedCleanup = false;
    await control.start();
    await emit(true);
    expect(pictures, 1);
  });

  test('native stream errors disable the shortcut and permit retry', () async {
    await control.start();
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      events.name,
      events.codec.encodeErrorEnvelope(code: 'unavailable'),
      (_) {},
    );
    await control.stop();
    await emit(true);
    expect(pictures, 0);
    expect(calls, ['listen', 'cancel']);

    await control.start();
    await emit(true);
    expect(pictures, 1);
  });

  test('native stream closure releases the listener', () async {
    await control.start();
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      events.name,
      null,
      (_) {},
    );
    await control.stop();
    await emit(true);
    expect(pictures, 0);
    expect(calls, ['listen', 'cancel']);
  });
}
