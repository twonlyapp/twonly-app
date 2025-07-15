// ignore_for_file: avoid_dynamic_calls

import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraZoomButtons extends StatefulWidget {
  const CameraZoomButtons({
    required this.controller,
    required this.updateScaleFactor,
    required this.scaleFactor,
    super.key,
  });

  final CameraController controller;
  final double scaleFactor;
  final Function updateScaleFactor;

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
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    showWideAngleZoom = (await widget.controller.getMinZoomLevel()) < 1;
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
    final isMiddleFocused = widget.scaleFactor >= 1 && widget.scaleFactor < 2;
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: ColoredBox(
          color: const Color.fromARGB(90, 0, 0, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showWideAngleZoom)
                TextButton(
                  style: zoomButtonStyle.copyWith(
                    foregroundColor: WidgetStateProperty.all(
                      (widget.scaleFactor < 1) ? Colors.yellow : Colors.white,
                    ),
                  ),
                  onPressed: () async {
                    final level = await widget.controller.getMinZoomLevel();
                    widget.updateScaleFactor(level);
                  },
                  child: FutureBuilder(
                    future: widget.controller.getMinZoomLevel(),
                    builder: (context, snap) {
                      if (snap.hasData) {
                        final minLevel = beautifulZoomScale(snap.data!);
                        final currentLevel =
                            beautifulZoomScale(widget.scaleFactor);
                        return Text(
                          widget.scaleFactor < 1
                              ? '${currentLevel}x'
                              : '${minLevel}x',
                          style: zoomTextStyle,
                        );
                      } else {
                        return const Text('');
                      }
                    },
                  ),
                ),
              TextButton(
                  style: zoomButtonStyle.copyWith(
                    foregroundColor: WidgetStateProperty.all(
                      isMiddleFocused ? Colors.yellow : Colors.white,
                    ),
                  ),
                  onPressed: () {
                    widget.updateScaleFactor(1.0);
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
                child: FutureBuilder(
                    future: widget.controller.getMaxZoomLevel(),
                    builder: (context, snap) {
                      if (snap.hasData) {
                        final maxLevel = max(
                          min((snap.data?.toInt())!, 2),
                          widget.scaleFactor,
                        );
                        return Text(
                            '${beautifulZoomScale(maxLevel.toDouble())}x',
                            style: zoomTextStyle);
                      } else {
                        return const Text('');
                      }
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
