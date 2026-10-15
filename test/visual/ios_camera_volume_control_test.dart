import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/ios_camera_volume_control.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const methods = MethodChannel(
    'com.yosemiteyss.flutter_volume_controller/method',
  );
  const events = MethodChannel(
    'com.yosemiteyss.flutter_volume_controller/event',
  );
  late IosCameraVolumeControl control;
  late List<MethodCall> calls;
  late int pictures;
  var rejectRegistration = false;
  var rejectCleanup = false;
  Completer<void>? registration;

  setUp(() {
    calls = [];
    pictures = 0;
    rejectRegistration = false;
    rejectCleanup = false;
    registration = null;
    control = IosCameraVolumeControl(onPressed: () async => pictures++);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(methods, (
      call,
    ) async {
      calls.add(call);
      if (rejectCleanup &&
          call.method == 'updateShowSystemUI' &&
          (call.arguments as Map)['showSystemUI'] == true) {
        throw PlatformException(code: 'cleanup');
      }
      return null;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(events, (
      call,
    ) async {
      calls.add(call);
      if (call.method == 'listen') {
        await registration?.future;
        if (rejectRegistration) {
          throw PlatformException(
            code: '1004',
            message: 'Failed to register volume listener',
            details: 'Session activation failed',
          );
        }
      } else if (rejectCleanup) {
        throw PlatformException(code: 'cleanup');
      }
      return null;
    });
  });

  tearDown(() async {
    await control.stop();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(methods, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(events, null);
  });

  Future<void> emit(double volume) async {
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      events.name,
      events.codec.encodeSuccessEnvelope('$volume'),
      (_) {},
    );
  }

  test(
    'registration failure restores volume controls and permits retry',
    () async {
      rejectRegistration = true;
      await control.start();

      expect(calls.map((call) => call.method), [
        'updateShowSystemUI',
        'listen',
        'cancel',
        'updateShowSystemUI',
      ]);
      expect(calls.last.arguments, {'showSystemUI': true});
      expect(pictures, 0);

      rejectRegistration = false;
      await control.start();
      await emit(0.5);
      await emit(0.6);
      expect(pictures, 1);
    },
  );

  test('volume changes restore the baseline and trigger the shutter', () async {
    await control.start();
    await control.start();
    expect(calls.where((call) => call.method == 'listen'), hasLength(1));

    await emit(0.5);
    await emit(0.5);
    expect(pictures, 0);
    await emit(0.6);
    expect(pictures, 1);
    expect(calls.last.method, 'setVolume');
    expect(calls.last.arguments, {'volume': 0.5, 'showSystemUI': false});
    await emit(0.5);
    expect(pictures, 1);

    await control.stop();
    await emit(0.7);
    expect(pictures, 1);
    expect(calls.last.arguments, {'showSystemUI': true});
  });

  test('stop during registration ignores events and cleans up once', () async {
    registration = Completer<void>();
    final starting = control.start();
    // Allow registration to reach the native listen call.
    await Future<void>.delayed(Duration.zero);
    final stopping = control.stop();
    await emit(0.5);
    await emit(0.6);
    registration!.complete();
    await starting;
    await stopping;

    expect(pictures, 0);
    expect(calls.where((call) => call.method == 'cancel'), hasLength(1));
    expect(calls.last.arguments, {'showSystemUI': true});
  });

  test('cleanup failures still attempt to restore system volume UI', () async {
    rejectRegistration = true;
    rejectCleanup = true;
    await control.start();
    expect(calls.last.method, 'updateShowSystemUI');
    expect(calls.last.arguments, {'showSystemUI': true});
  });

  test(
    'native stream errors disable the shortcut and restore volume UI',
    () async {
      await control.start();
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        events.name,
        events.codec.encodeErrorEnvelope(
          code: '1004',
          message: 'Session activation failed',
        ),
        (_) {},
      );
      // Wait for the cleanup queued by the native event handler.
      await control.stop();
      expect(pictures, 0);
      expect(calls.last.arguments, {'showSystemUI': true});
      expect(calls.where((call) => call.method == 'cancel'), hasLength(1));
    },
  );
}
