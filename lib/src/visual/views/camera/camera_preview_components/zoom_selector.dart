// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview_controller_view.dart';

String beautifulZoomScale(double scale) {
  var tmp = scale.toStringAsFixed(1);
  if (tmp[0] == '0') {
    tmp = tmp.substring(1, tmp.length);
  }
  return tmp;
}

class CameraZoomButtons extends StatelessWidget {
  const CameraZoomButtons({
    required this.controller,
    required this.updateScaleFactor,
    required this.scaleFactor,
    required this.selectedCameraDetails,
    required this.selectCamera,
    super.key,
  });

  final CameraController controller;
  final double scaleFactor;
  final Function updateScaleFactor;
  final SelectedCameraDetails selectedCameraDetails;
  final Future<void> Function(int sCameraId, bool init) selectCamera;

  @override
  Widget build(BuildContext context) {
    final showWideAngleZoom = selectedCameraDetails.minAvailableZoom < 1;

    int? wideCameraIndex;
    var index = AppEnvironment.cameras.indexWhere(
      (t) => t.lensType == CameraLensType.ultraWide,
    );
    if (index == -1) {
      index = AppEnvironment.cameras.indexWhere(
        (t) => t.lensType == CameraLensType.wide,
      );
    }
    if (index != -1) {
      wideCameraIndex = index;
    }

    final isFront = controller.description.lensDirection == CameraLensDirection.front;

    final showWideAngleZoomIOS = !showWideAngleZoom && Platform.isIOS && wideCameraIndex != null && !isFront;

    final zoomButtonStyle = TextButton.styleFrom(
      padding: EdgeInsets.zero,
      foregroundColor: Colors.white,
      minimumSize: const Size(40, 40),
      alignment: Alignment.center,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    const zoomTextStyle = TextStyle(fontSize: 13);
    final isSmallerFocused =
        scaleFactor < 1 || (showWideAngleZoomIOS && selectedCameraDetails.cameraId == wideCameraIndex);
    final isMiddleFocused =
        scaleFactor >= 1 &&
        scaleFactor < 2 &&
        !(showWideAngleZoomIOS && selectedCameraDetails.cameraId == wideCameraIndex);

    final maxLevel = max(
      min(selectedCameraDetails.maxAvailableZoom, 2),
      scaleFactor,
    );

    final minLevel = beautifulZoomScale(
      selectedCameraDetails.minAvailableZoom,
    );
    final currentLevel = beautifulZoomScale(scaleFactor);
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: ColoredBox(
          color: const Color.fromARGB(90, 0, 0, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showWideAngleZoom || showWideAngleZoomIOS)
                TextButton(
                  style: zoomButtonStyle.copyWith(
                    foregroundColor: WidgetStateProperty.all(
                      isSmallerFocused ? Colors.yellow : Colors.white,
                    ),
                  ),
                  onPressed: () async {
                    if (showWideAngleZoomIOS) {
                      if (wideCameraIndex != null) {
                        await selectCamera(wideCameraIndex, true);
                      }
                    } else {
                      final level = await controller.getMinZoomLevel();
                      updateScaleFactor(level);
                    }
                  },
                  child: showWideAngleZoomIOS
                      ? const Text('0.5')
                      : Text(
                          scaleFactor < 1 ? '${currentLevel}x' : '${minLevel}x',
                          style: zoomTextStyle,
                        ),
                ),
              TextButton(
                style: zoomButtonStyle.copyWith(
                  foregroundColor: WidgetStateProperty.all(
                    isMiddleFocused ? Colors.yellow : Colors.white,
                  ),
                ),
                onPressed: () async {
                  if (showWideAngleZoomIOS && selectedCameraDetails.cameraId == wideCameraIndex) {
                    await selectCamera(0, true);
                  } else {
                    updateScaleFactor(1.0);
                  }
                },
                child: Text(
                  isMiddleFocused ? '${beautifulZoomScale(scaleFactor)}x' : '1.0x',
                  style: zoomTextStyle,
                ),
              ),
              TextButton(
                style: zoomButtonStyle.copyWith(
                  foregroundColor: WidgetStateProperty.all(
                    (scaleFactor >= 2) ? Colors.yellow : Colors.white,
                  ),
                ),
                onPressed: () async {
                  final level = min(
                    await controller.getMaxZoomLevel(),
                    2,
                  ).toDouble();

                  if (showWideAngleZoomIOS && selectedCameraDetails.cameraId == wideCameraIndex) {
                    await selectCamera(0, true);
                  }
                  updateScaleFactor(level);
                },
                child: Text(
                  '${beautifulZoomScale(maxLevel.toDouble())}x',
                  style: zoomTextStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
