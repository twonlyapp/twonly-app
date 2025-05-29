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
  static CameraController? cameraController;
  static ScreenshotController screenshotController = ScreenshotController();
  static SelectedCameraDetails selectedCameraDetails = SelectedCameraDetails();

  @override
  void initState() {
    super.initState();
    selectCamera(0, true, false);
  }

  Future selectCamera(int sCameraId, bool init, bool enableAudio) async {
    final opts = await initializeCameraController(
        selectedCameraDetails, sCameraId, init, enableAudio);
    if (opts != null) {
      selectedCameraDetails = opts.$1;
      cameraController = opts.$2;
    }
    setState(() {});
  }

  Future toggleSelectedCamera() async {
    selectCamera((selectedCameraDetails.cameraId + 1) % 2, false, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onDoubleTap: toggleSelectedCamera,
        child: Stack(
          children: [
            SendToCameraPreview(),
            CameraPreviewControllerView(
              selectCamera: selectCamera,
              sendTo: widget.sendTo,
              isHomeView: false,
            ),
          ],
        ),
      ),
    );
  }
}
