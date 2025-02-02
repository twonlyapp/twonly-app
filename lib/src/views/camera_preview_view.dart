import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/components/media_view_sizing.dart';
import 'package:twonly/src/views/permissions_view.dart';
import 'package:twonly/src/views/share_image_editor_view.dart';

class CameraPreviewViewPermission extends StatefulWidget {
  const CameraPreviewViewPermission({super.key});

  @override
  State<CameraPreviewViewPermission> createState() =>
      _CameraPreviewViewPermission();
}

class _CameraPreviewViewPermission extends State<CameraPreviewViewPermission> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: checkPermissions(),
        builder: (context, snap) {
          if (snap.hasData) {
            if (snap.data!) {
              return CameraPreviewView();
            } else {
              return PermissionHandlerView(onSuccess: () {
                setState(() {});
              });
            }
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}

class CameraPreviewView extends StatefulWidget {
  const CameraPreviewView({super.key});

  @override
  State<CameraPreviewView> createState() => _CameraPreviewViewState();
}

class _CameraPreviewViewState extends State<CameraPreviewView> {
  double _lastZoom = 1;
  double _basePanY = 0;
  bool sharePreviewIsShown = false;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MediaViewSizing(
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: CameraAwesomeBuilder.custom(
          previewAlignment: Alignment.topLeft,
          sensorConfig: SensorConfig.single(
            aspectRatio: CameraAspectRatios.ratio_16_9,
            zoom: 0.07,
          ),
          previewFit: CameraPreviewFit.contain,
          progressIndicator: Container(),
          onMediaCaptureEvent: (event) {
            switch ((event.status, event.isPicture, event.isVideo)) {
              case (MediaCaptureStatus.capturing, true, false):
                debugPrint('Capturing picture...');
              case (MediaCaptureStatus.success, true, false):
                event.captureRequest.when(
                  single: (single) async {
                    final imageBytes = await single.file?.readAsBytes();
                    if (imageBytes == null || !context.mounted) return;
                    setState(() {
                      sharePreviewIsShown = true;
                    });
                    await Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (context, a1, a2) =>
                            ShareImageEditorView(imageBytes: imageBytes),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return child;
                        },
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                    setState(() {
                      sharePreviewIsShown = false;
                    });
                  },
                  multiple: (multiple) {
                    multiple.fileBySensor.forEach((key, value) {
                      debugPrint('multiple image taken: $key ${value?.path}');
                    });
                  },
                );
              case (MediaCaptureStatus.failure, true, false):
                debugPrint('Failed to capture picture: ${event.exception}');
              case (MediaCaptureStatus.capturing, false, true):
                debugPrint('Capturing video...');
              case (MediaCaptureStatus.success, false, true):
                event.captureRequest.when(
                  single: (single) {
                    debugPrint('Video saved: ${single.file?.path}');
                  },
                  multiple: (multiple) {
                    multiple.fileBySensor.forEach((key, value) {
                      debugPrint('multiple video taken: $key ${value?.path}');
                    });
                  },
                );
              case (MediaCaptureStatus.failure, false, true):
                debugPrint('Failed to capture video: ${event.exception}');
              default:
                debugPrint('Unknown event: $event');
            }
          },
          builder: (cameraState, preview) {
            return Stack(
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
                          (tmp);
                          _lastZoom = tmp;
                        });
                      }
                    },
                    onDoubleTap: () async {
                      cameraState.switchCameraSensor(
                          aspectRatio: CameraAspectRatios.ratio_16_9);
                    },
                  ),
                ),
                if (!sharePreviewIsShown)
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
            );
          },
          saveConfig: SaveConfig.photoAndVideo(
            photoPathBuilder: (sensors) async {
              final Directory extDir = await getTemporaryDirectory();
              final testDir = await Directory(
                '${extDir.path}/images',
              ).create(recursive: true);
              final String filePath =
                  '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
              return SingleCaptureRequest(filePath, sensors.first);
              // // Separate pictures taken with front and back camera
              // return MultipleCaptureRequest(
              //   {
              //     for (final sensor in sensors)
              //       sensor:
              //           '${testDir.path}/${sensor.position == SensorPosition.front ? 'front_' : "back_"}${DateTime.now().millisecondsSinceEpoch}.jpg',
              //   },
              // );
            },
          ),
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
