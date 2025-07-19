import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/views/camera/camera_preview_components/camera_preview.dart';
import 'package:twonly/src/views/camera/camera_preview_controller_view.dart';

class CameraSendToView extends StatefulWidget {
  const CameraSendToView(this.sendTo, {super.key});
  final Contact sendTo;
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
    selectCamera(0, true, false);
  }

  @override
  void dispose() {
    cameraController?.dispose();
    cameraController = null;
    selectedCameraDetails = SelectedCameraDetails();
    super.dispose();
  }

  Future<CameraController?> selectCamera(
      int sCameraId, bool init, bool enableAudio) async {
    final opts = await initializeCameraController(
        selectedCameraDetails, sCameraId, init, enableAudio);
    if (opts != null) {
      selectedCameraDetails = opts.$1;
      cameraController = opts.$2;
    }
    setState(() {});
    return cameraController;
  }

  Future<void> toggleSelectedCamera() async {
    await cameraController?.dispose();
    cameraController = null;
    await selectCamera((selectedCameraDetails.cameraId + 1) % 2, false, false);
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
              sendTo: widget.sendTo,
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
