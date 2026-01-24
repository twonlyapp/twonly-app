import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twonly/src/views/camera/camera_preview_components/camera_preview.dart';
import 'package:twonly/src/views/camera/camera_preview_components/camera_preview_controller_view.dart';
import 'package:twonly/src/views/camera/camera_preview_components/main_camera_controller.dart';

class QrCodeScanner extends StatefulWidget {
  const QrCodeScanner({super.key});
  @override
  State<QrCodeScanner> createState() => QrCodeScannerState();
}

class QrCodeScannerState extends State<QrCodeScanner> {
  final MainCameraController _mainCameraController = MainCameraController();

  @override
  void initState() {
    super.initState();
    _mainCameraController.setState = () {
      if (mounted) setState(() {});
    };
    unawaited(_mainCameraController.selectCamera(0, true));
  }

  @override
  void dispose() {
    _mainCameraController.closeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onDoubleTap: _mainCameraController.onDoubleTap,
        onTapDown: _mainCameraController.onTapDown,
        child: Stack(
          children: [
            MainCameraPreview(
              mainCameraController: _mainCameraController,
            ),
            CameraPreviewControllerView(
              mainController: _mainCameraController,
              hideControllers: true,
              isVisible: true,
            ),
          ],
        ),
      ),
    );
  }
}
