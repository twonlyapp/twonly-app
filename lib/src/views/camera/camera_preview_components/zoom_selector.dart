// ignore_for_file: avoid_dynamic_calls

import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/views/camera/camera_preview_controller_view.dart';

class CameraZoomButtons extends StatefulWidget {
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
  final Future<void> Function(int sCameraId, bool init, bool enableAudio)
      selectCamera;

  @override
  State<CameraZoomButtons> createState() => _CameraZoomButtonsState();
}

String beautifulZoomScale(double scale) {
  var tmp = scale.toStringAsFixed(1);
  if (tmp[0] == '0') {
    tmp = tmp.substring(1, tmp.length);
  }
  return tmp;
}

class _CameraZoomButtonsState extends State<CameraZoomButtons> {
  bool showWideAngleZoom = false;
  bool showWideAngleZoomIOS = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    showWideAngleZoom = (await widget.controller.getMinZoomLevel()) < 1;
    if (!showWideAngleZoom && Platform.isIOS && gCameras.length == 3) {
      showWideAngleZoomIOS = true;
    }
    if (_isDisposed) return;
    setState(() {});
  }

  @override
  void dispose() {
    _isDisposed = true; // Set the flag to true when disposing
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zoomButtonStyle = TextButton.styleFrom(
      padding: EdgeInsets.zero,
      foregroundColor: Colors.white,
      minimumSize: const Size(40, 40),
      alignment: Alignment.center,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    const zoomTextStyle = TextStyle(fontSize: 13);
    final isSmallerFocused = widget.scaleFactor < 1 ||
        (showWideAngleZoomIOS && widget.selectedCameraDetails.cameraId == 2);
    final isMiddleFocused = widget.scaleFactor >= 1 &&
        widget.scaleFactor < 2 &&
        !(showWideAngleZoomIOS && widget.selectedCameraDetails.cameraId == 2);

    final maxLevel = max(
      min(widget.selectedCameraDetails.maxAvailableZoom, 2),
      widget.scaleFactor,
    );

    final minLevel =
        beautifulZoomScale(widget.selectedCameraDetails.minAvailableZoom);
    final currentLevel = beautifulZoomScale(widget.scaleFactor);
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
                      await widget.selectCamera(2, true, false);
                    } else {
                      final level = await widget.controller.getMinZoomLevel();
                      widget.updateScaleFactor(level);
                    }
                  },
                  child: showWideAngleZoomIOS
                      ? const Text('0.5')
                      : Text(
                          widget.scaleFactor < 1
                              ? '${currentLevel}x'
                              : '${minLevel}x',
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
                    if (showWideAngleZoomIOS &&
                        widget.selectedCameraDetails.cameraId == 2) {
                      await widget.selectCamera(0, true, false);
                    } else {
                      widget.updateScaleFactor(1.0);
                    }
                  },
                  child: Text(
                    isMiddleFocused
                        ? '${beautifulZoomScale(widget.scaleFactor)}x'
                        : '1.0x',
                    style: zoomTextStyle,
                  )),
              TextButton(
                style: zoomButtonStyle.copyWith(
                  foregroundColor: WidgetStateProperty.all(
                    (widget.scaleFactor >= 2) ? Colors.yellow : Colors.white,
                  ),
                ),
                onPressed: () async {
                  final level =
                      min(await widget.controller.getMaxZoomLevel(), 2)
                          .toDouble();
                  widget.updateScaleFactor(level);
                },
                child: Text('${beautifulZoomScale(maxLevel.toDouble())}x',
                    style: zoomTextStyle),
              )
            ],
          ),
        ),
      ),
    );
  }
}
