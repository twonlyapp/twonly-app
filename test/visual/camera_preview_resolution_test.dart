import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/main_camera_controller.dart';

void main() {
  test('selfie preview uses 720p while rear screenshot detail stays 1080p', () {
    expect(
      cameraPreviewResolution(CameraLensDirection.front),
      ResolutionPreset.high,
    );
    expect(
      cameraPreviewResolution(CameraLensDirection.back),
      ResolutionPreset.veryHigh,
    );
  });
}
