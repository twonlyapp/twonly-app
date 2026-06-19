import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview_controller_view.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/main_camera_controller.dart';

class CameraSendToView extends StatefulWidget {
  const CameraSendToView(this.sendToGroup, {super.key});
  final Group sendToGroup;
  @override
  State<CameraSendToView> createState() => CameraSendToViewState();
}

class CameraSendToViewState extends State<CameraSendToView> {
  final MainCameraController _mainCameraController = MainCameraController();

  @override
  void initState() {
    super.initState();
    _mainCameraController.setState = () {
      if (mounted) setState(() {});
    };
    Permission.camera.isGranted.then((hasPermission) {
      if (hasPermission && mounted) {
        unawaited(_mainCameraController.selectCamera(0, true));
      }
    });
  }

  @override
  void dispose() {
    _mainCameraController.setState = null;
    _mainCameraController.closeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MainCameraPreview(
            mainCameraController: _mainCameraController,
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: _mainCameraController.onDoubleTap,
              onTapDown: _mainCameraController.onTapDown,
            ),
          ),
          Positioned.fill(
            child: CameraPreviewControllerView(
              mainController: _mainCameraController,
              sendToGroup: widget.sendToGroup,
              isVisible: true,
            ),
          ),
        ],
      ),
    );
  }
}
