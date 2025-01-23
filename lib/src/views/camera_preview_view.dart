// import 'package:camera/camera.dart';
// import 'camera_editor_view.dart';
// import 'package:flutter/gestures.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:camerawesome/camerawesome_plugin.dart';

class CameraPreviewView extends StatefulWidget {
  const CameraPreviewView({super.key});

  @override
  State<CameraPreviewView> createState() => _CameraPreviewViewState();
}

class _CameraPreviewViewState extends State<CameraPreviewView> {
  double _lastZoom = 1;
  double _basePanY = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 50, bottom: 30, left: 5, right: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: CameraAwesomeBuilder.custom(
          progressIndicator: Container(),
          builder: (cameraState, preview) {
            return Container(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onPanStart: (details) async {
                        setState(() {
                          _basePanY = details.localPosition.dy;
                        });
                      },
                      onPanUpdate: (details) async {
                        var diff = _basePanY - details.localPosition.dy;
                        if (diff > 200) diff = 200;
                        if (diff < 0) diff = 0;
                        var tmp = (diff / 200 * 50).toInt() / 50;
                        if (tmp != _lastZoom) {
                          cameraState.sensorConfig.setZoom(tmp);
                          setState(() {
                            _lastZoom = tmp;
                          });
                        }
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        children: [
                          AwesomeZoomSelector(state: cameraState),
                          const SizedBox(height: 30),
                          GestureDetector(
                            onTap: () async {
                              cameraState.when(
                                  onPhotoMode: (picState) =>
                                      picState.takePhoto());
                              // await takePicture();
                            },
                            onLongPress: () async {},
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                height: 100,
                                width: 100,
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    width: 7,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          saveConfig: SaveConfig.photoAndVideo(),
          previewPadding: const EdgeInsets.all(10),
          // onPreviewTapBuilder: (state) => OnPreviewTap(
          //   onTap: (Offset position, PreviewSize flutterPreviewSize,
          //       PreviewSize pixelPreviewSize) {
          //     state.when(onPhotoMode: (picState) => picState.takePhoto());
          //   },
          //   onTapPainter: (tapPosition) => TweenAnimationBuilder(
          //     key: ValueKey(tapPosition),
          //     tween: Tween<double>(begin: 1.0, end: 0.0),
          //     duration: const Duration(milliseconds: 500),
          //     builder: (context, anim, child) {
          //       return Transform.rotate(
          //         angle: anim * 2 * pi,
          //         child: Transform.scale(
          //           scale: 4 * anim,
          //           child: child,
          //         ),
          //       );
          //     },
          //     child: const Icon(
          //       Icons.camera,
          //       color: Colors.white,
          //     ),
          //   ),
          // ),
        ),
      ),
    );
  }
}

String beautifulZoomScale(double scale) {
  var tmp = scale.toStringAsFixed(1);
  if (tmp[0] == "0") {
    tmp = tmp.substring(1, tmp.length);
  }
  return tmp;
}

class CameraZoomButtons extends StatefulWidget {
  const CameraZoomButtons(
      {super.key,
      required this.isFront,
      required this.updateScaleFactor,
      required this.scaleFactor});

  final bool isFront;
  final double scaleFactor;
  final Function updateScaleFactor;

  @override
  State<CameraZoomButtons> createState() => _CameraZoomButtonsState();
}

class _CameraZoomButtonsState extends State<CameraZoomButtons> {
  @override
  Widget build(BuildContext context) {
    final zoomButtonStyle = TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: Colors.white,
        minimumSize: Size(40, 40),
        alignment: Alignment.center,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap);

    final zoomTextStyle = TextStyle(fontSize: 13);
    return ClipRRect(
      borderRadius: BorderRadius.circular(40.0),
      child: Container(
        color: const Color.fromARGB(90, 0, 0, 0),
        child: Row(
          children: widget.isFront
              ? []
              : [
                  TextButton(
                    style: zoomButtonStyle,
                    onPressed: () async {
                      // var level = await widget.controller.getMinZoomLevel();
                      // widget.updateScaleFactor(level);
                    },
                    child: Text(""),
                    // child: FutureBuilder(
                    //     future: widget.controller.getMinZoomLevel(),
                    //     builder: (context, snap) {
                    //       if (snap.hasData) {
                    //         var minLevel =
                    //             beautifulZoomScale(snap.data!.toDouble());
                    //         var currentLevel =
                    //             beautifulZoomScale(widget.scaleFactor);
                    //         return Text(
                    //           widget.scaleFactor < 1
                    //               ? "${currentLevel}x"
                    //               : "${minLevel}x",
                    //           style: zoomTextStyle,
                    //         );
                    //       } else {
                    //         return Text("");
                    //       }
                    //     }),
                  ),
                  TextButton(
                      style: zoomButtonStyle,
                      onPressed: () {
                        widget.updateScaleFactor(1.0);
                      },
                      child: Text(
                        widget.scaleFactor >= 1
                            ? "${beautifulZoomScale(widget.scaleFactor)}x"
                            : "1.0x",
                        style: zoomTextStyle,
                      )),
                  TextButton(
                    style: zoomButtonStyle,
                    onPressed: () async {
                      // var level = await widget.controller.getMaxZoomLevel();
                      // widget.updateScaleFactor(level);
                    },
                    child: Text(""),
                    // child: FutureBuilder(
                    //     future: widget.controller.getMaxZoomLevel(),
                    //     builder: (context, snap) {
                    //       if (snap.hasData) {
                    //         var maxLevel = snap.data?.toInt();
                    //         return Text("${maxLevel}x", style: zoomTextStyle);
                    //       } else {
                    //         return Text("");
                    //       }
                    //     }),
                  )
                ],
        ),
      ),
    );
  }
}
