import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/visual/helpers/media_view_sizing.helper.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/main_camera_controller.dart';

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
      child: MediaViewSizingHelper(
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
                          .cameraController!
                          .value
                          .previewSize!
                          .height,
                      height: mainCameraController
                          .cameraController!
                          .value
                          .previewSize!
                          .width,
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
            if (mainCameraController.focusPointOffset != null &&
                !mainCameraController.isSharePreviewIsShown)
              AspectRatio(
                aspectRatio: 9 / 16,
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: mainCameraController
                          .cameraController!
                          .value
                          .previewSize!
                          .height,
                      height: mainCameraController
                          .cameraController!
                          .value
                          .previewSize!
                          .width,
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
