import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/key_verification.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview_controller_view.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/main_camera_controller.dart';

class QrCodeScannerView extends StatefulWidget {
  const QrCodeScannerView({
    this.contact,
    this.openToVerify = false,
    super.key,
  });

  final Contact? contact;
  final bool openToVerify;

  @override
  State<QrCodeScannerView> createState() => QrCodeScannerViewState();
}

class QrCodeScannerViewState extends State<QrCodeScannerView> {
  final MainCameraController _mainCameraController = MainCameraController();

  @override
  void initState() {
    super.initState();
    _mainCameraController.setState = () {
      if (mounted) setState(() {});
    };
    if (widget.openToVerify && widget.contact != null) {
      _mainCameraController.onVerificationSuccessDismissed = (contact) {
        if (mounted) {
          KeyVerificationService.closeVerificationFlows(context);
        }
      };
    }
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
              hideControllers: true,
              isVisible: true,
            ),
          ),
          if (widget.openToVerify)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.contact != null
                      ? context.lang.qrScannerVerifyUserHint(
                          getContactDisplayName(widget.contact!),
                        )
                      : context.lang.qrScannerVerifyHint,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
