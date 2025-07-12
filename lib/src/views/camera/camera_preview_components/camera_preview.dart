import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/src/views/camera/camera_send_to_view.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';
import 'package:twonly/src/views/home.view.dart';

class HomeViewCameraPreview extends StatefulWidget {
  const HomeViewCameraPreview({
    super.key,
  });

  @override
  State<HomeViewCameraPreview> createState() => _HomeViewCameraPreviewState();
}

class _HomeViewCameraPreviewState extends State<HomeViewCameraPreview> {
  @override
  Widget build(BuildContext context) {
    if (HomeViewState.cameraController == null ||
        !HomeViewState.cameraController!.value.isInitialized) {
      return Container();
    }
    return Positioned.fill(
      child: MediaViewSizing(
        child: Screenshot(
          controller: HomeViewState.screenshotController,
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width:
                      HomeViewState.cameraController!.value.previewSize!.height,
                  height:
                      HomeViewState.cameraController!.value.previewSize!.width,
                  child: CameraPreview(HomeViewState.cameraController!),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SendToCameraPreview extends StatefulWidget {
  const SendToCameraPreview({
    super.key,
  });

  @override
  State<SendToCameraPreview> createState() => _SendToCameraPreviewState();
}

class _SendToCameraPreviewState extends State<SendToCameraPreview> {
  @override
  Widget build(BuildContext context) {
    if (CameraSendToViewState.cameraController == null ||
        !CameraSendToViewState.cameraController!.value.isInitialized) {
      return Container();
    }
    return Positioned.fill(
      child: MediaViewSizing(
        child: Screenshot(
          controller: CameraSendToViewState.screenshotController,
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: CameraSendToViewState
                      .cameraController!.value.previewSize!.height,
                  height: CameraSendToViewState
                      .cameraController!.value.previewSize!.width,
                  child: CameraPreview(CameraSendToViewState.cameraController!),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
