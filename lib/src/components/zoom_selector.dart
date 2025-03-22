import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraZoomButtons extends StatefulWidget {
  const CameraZoomButtons(
      {super.key,
      required this.controller,
      required this.updateScaleFactor,
      required this.scaleFactor});

  final CameraController controller;
  final double scaleFactor;
  final Function updateScaleFactor;

  @override
  State<CameraZoomButtons> createState() => _CameraZoomButtonsState();
}

String beautifulZoomScale(double scale) {
  var tmp = scale.toStringAsFixed(1);
  if (tmp[0] == "0") {
    tmp = tmp.substring(1, tmp.length);
  }
  return tmp;
}

class _CameraZoomButtonsState extends State<CameraZoomButtons> {
  @override
  Widget build(BuildContext context) {
    var zoomButtonStyle = TextButton.styleFrom(
      padding: EdgeInsets.zero,
      foregroundColor: Colors.white,
      minimumSize: Size(40, 40),
      alignment: Alignment.center,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    final zoomTextStyle = TextStyle(fontSize: 13);
    final isMiddleFocused = widget.scaleFactor >= 1 && widget.scaleFactor < 2;
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40.0),
        child: Container(
          color: const Color.fromARGB(90, 0, 0, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                style: zoomButtonStyle.copyWith(
                  foregroundColor: WidgetStateProperty.all(
                    (widget.scaleFactor < 1) ? Colors.yellow : Colors.white,
                  ),
                ),
                onPressed: () async {
                  var level = await widget.controller.getMinZoomLevel();
                  widget.updateScaleFactor(level);
                },
                child: FutureBuilder(
                  future: widget.controller.getMinZoomLevel(),
                  builder: (context, snap) {
                    if (snap.hasData) {
                      var minLevel = beautifulZoomScale(snap.data!.toDouble());
                      var currentLevel = beautifulZoomScale(widget.scaleFactor);
                      return Text(
                        widget.scaleFactor < 1
                            ? "${currentLevel}x"
                            : "${minLevel}x",
                        style: zoomTextStyle,
                      );
                    } else {
                      return Text("");
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
                    (isMiddleFocused)
                        ? "${beautifulZoomScale(widget.scaleFactor)}x"
                        : "1.0x",
                    style: zoomTextStyle,
                  )),
              TextButton(
                style: zoomButtonStyle.copyWith(
                  foregroundColor: WidgetStateProperty.all(
                    (widget.scaleFactor >= 2) ? Colors.yellow : Colors.white,
                  ),
                ),
                onPressed: () async {
                  var level = min(await widget.controller.getMaxZoomLevel(), 2)
                      .toDouble();
                  widget.updateScaleFactor(level);
                },
                child: FutureBuilder(
                    future: widget.controller.getMaxZoomLevel(),
                    builder: (context, snap) {
                      if (snap.hasData) {
                        var maxLevel = max(
                          min((snap.data?.toInt())!, 2),
                          widget.scaleFactor,
                        );
                        return Text(
                            "${beautifulZoomScale(maxLevel.toDouble())}x",
                            style: zoomTextStyle);
                      } else {
                        return Text("");
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
