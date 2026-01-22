import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/utils/screenshot.dart';
import 'package:twonly/src/views/camera/camera_preview_components/main_camera_controller.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';

class MainCameraPreview extends StatelessWidget {
  const MainCameraPreview({
    required this.mainCameraController,
    super.key,
  });

  final MainCameraController mainCameraController;

  @override
  Widget build(BuildContext context) {
    if (mainCameraController.cameraController == null ||
        !mainCameraController.cameraController!.value.isInitialized) {
      return Container();
    }
    return Positioned.fill(
      child: MediaViewSizing(
        requiredHeight: 0,
        additionalPadding: 59,
        bottomNavigation: Container(),
        child: Stack(
          children: [
            Screenshot(
              controller: mainCameraController.screenshotController,
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: mainCameraController
                          .cameraController!.value.previewSize!.height,
                      height: mainCameraController
                          .cameraController!.value.previewSize!.width,
                      child: CameraPreview(
                        key: mainCameraController.cameraPreviewKey,
                        mainCameraController.cameraController!,
                        child: Stack(
                          children: [
                            if (mainCameraController.customPaint != null)
                              Positioned.fill(
                                child: mainCameraController.customPaint!,
                              ),
                            if (mainCameraController.facePaint != null)
                              Positioned.fill(
                                child: mainCameraController.facePaint!,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (mainCameraController.focusPointOffset != null)
              AspectRatio(
                aspectRatio: 9 / 16,
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: mainCameraController
                          .cameraController!.value.previewSize!.height,
                      height: mainCameraController
                          .cameraController!.value.previewSize!.width,
                      child: Stack(
                        children: [
                          Positioned(
                            top: mainCameraController.focusPointOffset!.dy - 40,
                            left:
                                mainCameraController.focusPointOffset!.dx - 40,
                            child: Container(
                              height: 80,
                              width: 80,
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withAlpha(150),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
