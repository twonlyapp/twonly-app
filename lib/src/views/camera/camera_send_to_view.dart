import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/views/camera/camera_preview_components/camera_preview.dart';
import 'package:twonly/src/views/camera/camera_preview_controller_view.dart';

class CameraSendToView extends StatefulWidget {
  const CameraSendToView(this.sendToGroup, {super.key});
  final Group sendToGroup;
  @override
  State<CameraSendToView> createState() => CameraSendToViewState();
}

class CameraSendToViewState extends State<CameraSendToView> {
  CameraController? cameraController;
  ScreenshotController screenshotController = ScreenshotController();
  SelectedCameraDetails selectedCameraDetails = SelectedCameraDetails();

  @override
  void initState() {
    super.initState();
    unawaited(selectCamera(0, true));
  }

  @override
  void dispose() {
    cameraController?.dispose();
    cameraController = null;
    selectedCameraDetails = SelectedCameraDetails();
    super.dispose();
  }

  Future<CameraController?> selectCamera(
    int sCameraId,
    bool init,
  ) async {
    final opts = await initializeCameraController(
      selectedCameraDetails,
      sCameraId,
      init,
    );
    if (opts != null) {
      selectedCameraDetails = opts.$1;
      cameraController = opts.$2;
    }
    setState(() {});
    return cameraController;
  }

  /// same function also in home.view.dart
  Future<void> toggleSelectedCamera() async {
    if (cameraController == null) return;
    // do not allow switching camera when recording
    if (cameraController!.value.isRecordingVideo) {
      return;
    }
    await cameraController!.dispose();
    cameraController = null;
    await selectCamera((selectedCameraDetails.cameraId + 1) % 2, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onDoubleTap: toggleSelectedCamera,
        child: Stack(
          children: [
            SendToCameraPreview(
              cameraController: cameraController,
              screenshotController: screenshotController,
            ),
            CameraPreviewControllerView(
              selectCamera: selectCamera,
              sendToGroup: widget.sendToGroup,
              cameraController: cameraController,
              selectedCameraDetails: selectedCameraDetails,
              screenshotController: screenshotController,
            ),
          ],
        ),
      ),
    );
  }
}
