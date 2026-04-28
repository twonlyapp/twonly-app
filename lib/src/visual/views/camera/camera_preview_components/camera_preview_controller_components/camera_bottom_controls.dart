import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:twonly/src/visual/views/camera/camera_preview_components/face_filters.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/main_camera_controller.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/zoom_selector.dart';

class CameraBottomControls extends StatelessWidget {
  const CameraBottomControls({
    required this.mainController,
    required this.isVideoRecording,
    required this.isFront,
    required this.keyTriggerButton,
    required this.onTakePicture,
    required this.onPressSideButtonLeft,
    required this.onPressSideButtonRight,
    required this.updateScaleFactor,
    super.key,
  });

  final MainCameraController mainController;
  final bool isVideoRecording;
  final bool isFront;
  final GlobalKey keyTriggerButton;
  final VoidCallback onTakePicture;
  final VoidCallback onPressSideButtonLeft;
  final VoidCallback onPressSideButtonRight;
  final Future<void> Function(double) updateScaleFactor;

  MainCameraController get mc => mainController;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          children: [
            if (mc.cameraController?.value.isInitialized == true &&
                mc.selectedCameraDetails.isZoomAble &&
                !isVideoRecording)
              SizedBox(
                width: 120,
                child: CameraZoomButtons(
                  key: mc.zoomButtonKey,
                  scaleFactor: mc.selectedCameraDetails.scaleFactor,
                  updateScaleFactor: updateScaleFactor,
                  selectCamera: mc.selectCamera,
                  selectedCameraDetails: mc.selectedCameraDetails,
                  controller: mc.cameraController!,
                ),
              ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isVideoRecording) _buildSideButtonLeft(),
                _buildShutterButton(),
                if (!isVideoRecording)
                  if (isFront)
                    _buildSideButtonRight()
                  else
                    const SizedBox(width: 80),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideButtonLeft() {
    return GestureDetector(
      onTap: onPressSideButtonLeft,
      child: Align(
        child: Container(
          height: 50,
          width: 80,
          padding: const EdgeInsets.all(2),
          child: Center(
            child: FaIcon(
              mc.isSelectingFaceFilters
                  ? mc.currentFilterType.index == 1
                        ? FontAwesomeIcons.xmark
                        : FontAwesomeIcons.arrowLeft
                  : FontAwesomeIcons.photoFilm,
              color: Colors.white,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: onTakePicture,
      key: keyTriggerButton,
      child: Align(
        child: Container(
          height: 100,
          width: 100,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: 7,
              color: isVideoRecording ? Colors.red : Colors.white,
            ),
          ),
          child: mc.currentFilterType.preview,
        ),
      ),
    );
  }

  Widget _buildSideButtonRight() {
    return GestureDetector(
      onTap: onPressSideButtonRight,
      child: Align(
        child: Container(
          height: 50,
          width: 80,
          padding: const EdgeInsets.all(2),
          child: Center(
            child: FaIcon(
              mc.isSelectingFaceFilters
                  ? mc.currentFilterType.index ==
                            FaceFilterType.values.length - 1
                        ? FontAwesomeIcons.xmark
                        : FontAwesomeIcons.arrowRight
                  : FontAwesomeIcons.faceGrinTongueSquint,
              color: Colors.white,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }
}
