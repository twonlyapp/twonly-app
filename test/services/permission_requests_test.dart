import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/src/services/permission_requests.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'camera batch and microphone request never overlap on the platform',
    () async {
      final release = Completer<void>();
      final started = Completer<void>();
      var requests = 0;
      var active = 0;
      var maxActive = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        expect(call.method, 'requestPermissions');
        requests++;
        active++;
        if (active > maxActive) maxActive = active;
        if (requests == 1) {
          started.complete();
          await release.future;
        }
        active--;
        return {for (final id in call.arguments as List) id: 1};
      });
      final batch = requestPermissions([
        Permission.camera,
        Permission.microphone,
        Permission.notification,
      ]);
      await started.future;
      final microphone = requestPermissions([Permission.microphone]);
      await Future<void>.delayed(Duration.zero);
      expect(requests, 1);
      release.complete();
      expect((await batch)[Permission.camera], PermissionStatus.granted);
      expect(
        (await microphone)[Permission.microphone],
        PermissionStatus.granted,
      );
      expect(requests, 2);
      expect(maxActive, 1);
    },
  );

  test('a failed prompt releases the queue for the next request', () async {
    var requests = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (++requests == 1) {
        throw PlatformException(code: 'permission_unavailable');
      }
      return {Permission.microphone.value: 1};
    });
    await expectLater(
      requestPermissions([Permission.camera]),
      throwsA(isA<PlatformException>()),
    );
    expect(
      (await requestPermissions([
        Permission.microphone,
      ]))[Permission.microphone],
      PermissionStatus.granted,
    );
  });
}
