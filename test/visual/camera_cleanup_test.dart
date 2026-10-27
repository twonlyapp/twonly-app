import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/main_camera_controller.dart';

class _Camera extends CameraController {
  _Camera({required this.error, bool initialized = false})
    : super(
        const CameraDescription(
          name: 'test',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 0,
        ),
        ResolutionPreset.high,
      ) {
    value = value.copyWith(isInitialized: initialized);
  }
  final PlatformException error;
  int disposals = 0;

  @override
  Future<void> dispose() async {
    disposals++;
    await super.dispose();
    throw error;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PlatformException missingPreview() => PlatformException(
    code: 'IllegalStateException',
    message:
        'releaseFlutterSurfaceTexture() cannot be called if the flutterSurfaceProducer for the camera preview has not yet been initialized.',
  );

  test('cleanup after failed setup permits fallback initialization', () async {
    final camera = _Camera(error: missingPreview());
    await disposeCameraController(camera);
    expect(camera.disposals, 1);
  });

  test(
    'a missing surface on an initialized camera remains reportable',
    () async {
      final camera = _Camera(error: missingPreview(), initialized: true);
      await expectLater(
        disposeCameraController(camera),
        throwsA(same(camera.error)),
      );
    },
  );

  test('unrelated camera cleanup failures remain reportable', () async {
    final camera = _Camera(
      error: PlatformException(code: 'CameraDisconnected'),
    );
    await expectLater(
      disposeCameraController(camera),
      throwsA(same(camera.error)),
    );
  });
}
