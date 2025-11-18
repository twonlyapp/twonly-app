import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';

class HomeViewCameraPreview extends StatelessWidget {
  const HomeViewCameraPreview({
    required this.controller,
    required this.screenshotController,
    super.key,
  });

  final CameraController? controller;
  final ScreenshotController screenshotController;

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container();
    }
    return Positioned.fill(
      child: MediaViewSizing(
        requiredHeight: 80,
        bottomNavigation: Container(),
        child: Screenshot(
          controller: screenshotController,
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller!.value.previewSize!.height,
                  height: controller!.value.previewSize!.width,
                  child: CameraPreview(controller!),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SendToCameraPreview extends StatelessWidget {
  const SendToCameraPreview({
    required this.cameraController,
    required this.screenshotController,
    super.key,
  });

  final CameraController? cameraController;
  final ScreenshotController screenshotController;

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return Container();
    }
    return Positioned.fill(
      child: MediaViewSizing(
        requiredHeight: 80,
        bottomNavigation: Container(),
        child: Screenshot(
          controller: screenshotController,
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: cameraController!.value.previewSize!.height,
                  height: cameraController!.value.previewSize!.width,
                  child: CameraPreview(cameraController!),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
