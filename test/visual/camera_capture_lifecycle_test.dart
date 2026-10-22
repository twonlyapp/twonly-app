import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview_controller_view.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/main_camera_controller.dart';

import '../mocks/user_config.dart';

class _PendingScreenshotController extends ScreenshotController {
  final result = Completer<ScreenshotImageHelper?>();
  int captures = 0;

  @override
  Future<ScreenshotImageHelper?> capture({
    double? pixelRatio,
    int retries = 20,
  }) {
    captures++;
    return result.future;
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const permissions = MethodChannel('flutter.baseflow.com/permissions/methods');
  late MainCameraController controller;
  late _PendingScreenshotController screenshot;

  setUp(() async {
    AppEnvironment.initTesting();
    await locator.reset();
    locator.registerSingleton<UserService>(
      UserService()
        ..currentUser = testUserConfig(
          userId: 1,
          username: 'me',
          displayName: 'Me',
          subscriptionPlan: 'Free',
          currentSetupPage: null,
          appVersion: 191,
        ),
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      permissions,
      (_) async => 1,
    );
  });

  tearDown(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(permissions, null);
    await locator.reset();
  });

  Future<Future<void> Function()> mountCamera(WidgetTester tester) async {
    screenshot = _PendingScreenshotController();
    controller = MainCameraController()..screenshotController = screenshot;
    await tester.pumpWidget(
      MaterialApp(
        home: CameraPreviewView(
          mainCameraController: controller,
          isVisible: false,
          hideControllers: true,
        ),
      ),
    );
    final dynamic state = tester.state(find.byType(CameraPreviewView));
    // Retain the shutter callback to exercise completions after disposal.
    // ignore: avoid_dynamic_calls
    return state.takePicture as Future<void> Function();
  }

  testWidgets('a shutter callback after disposal does nothing', (tester) async {
    final takePicture = await mountCamera(tester);
    await tester.pumpWidget(const SizedBox.shrink());

    await takePicture();

    expect(controller.isSharePreviewIsShown, isFalse);
    expect(screenshot.captures, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposal during capture stops before opening the editor', (
    tester,
  ) async {
    final takePicture = await mountCamera(tester);
    final takingPicture = takePicture();
    await tester.pump();
    expect(screenshot.captures, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    screenshot.result.complete(ScreenshotImageHelper());
    await tester.pump();
    await takingPicture;

    expect(tester.takeException(), isNull);
  });
}
