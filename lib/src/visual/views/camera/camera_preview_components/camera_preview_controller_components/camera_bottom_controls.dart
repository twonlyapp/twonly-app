import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:twonly/src/visual/views/camera/camera_preview_components/face_filters.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/main_camera_controller.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/zoom_selector.dart';

class CameraBottomControls extends StatelessWidget {
  const CameraBottomControls({
    required this.mainController,
    required this.isVideoRecording,
    required this.videoRecordingLocked,
    required this.isFront,
    required this.keyTriggerButton,
    required this.keyLockButton,
    required this.onTakePicture,
    required this.onPressSideButtonLeft,
    required this.onPressSideButtonRight,
    required this.updateScaleFactor,
    required this.onStopVideoRecording,
    super.key,
  });

  final MainCameraController mainController;
  final bool isVideoRecording;
  final bool videoRecordingLocked;
  final bool isFront;
  final GlobalKey keyTriggerButton;
  final GlobalKey keyLockButton;
  final VoidCallback onTakePicture;
  final VoidCallback onPressSideButtonLeft;
  final VoidCallback onPressSideButtonRight;
  final Future<void> Function(double) updateScaleFactor;
  final VoidCallback onStopVideoRecording;

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
                if (!isVideoRecording)
                  _buildSideButtonLeft()
                else
                  _buildLockOrStopButton(),
                _buildShutterButton(),
                if (!isVideoRecording)
                  if (isFront)
                    _buildSideButtonRight()
                  else
                    const SizedBox(width: 80)
                else
                  const SizedBox(width: 80),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockOrStopButton() {
    if (videoRecordingLocked) {
      // Show stop button
      return GestureDetector(
        onTap: onStopVideoRecording,
        child: Container(
          key: keyLockButton,
          height: 50,
          width: 80,
          padding: const EdgeInsets.all(2),
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      );
    } else {
      // Show animated lock icon (slide here to lock)
      return _AnimatedLockButton(keyLockButton: keyLockButton);
    }
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

class _AnimatedLockButton extends StatefulWidget {
  const _AnimatedLockButton({required this.keyLockButton});

  final GlobalKey keyLockButton;

  @override
  State<_AnimatedLockButton> createState() => _AnimatedLockButtonState();
}

class _AnimatedLockButtonState extends State<_AnimatedLockButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnim = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
        );
      },
      child: Container(
        key: widget.keyLockButton,
        height: 50,
        width: 80,
        padding: const EdgeInsets.all(2),
        child: const Center(
          child: FaIcon(
            FontAwesomeIcons.lock,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
    );
  }
}
