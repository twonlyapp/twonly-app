import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/components/zoom_selector.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/components/image_editor/action_button.dart';
import 'package:twonly/src/components/media_view_sizing.dart';
import 'package:twonly/src/components/permissions_view.dart';
import 'package:twonly/src/views/camera_to_share/share_image_editor_view.dart';

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
            return Container();
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
  double scaleFactor = 1;
  bool sharePreviewIsShown = false;
  bool isFlashOn = false;
  bool showSelfieFlash = false;
  int cameraId = 0;
  bool isZoomAble = false;
  double basePanY = 0;
  double baseScaleFactor = 0;
  bool cameraLoaded = false;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  late CameraController controller;
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    selectCamera(0, init: true);

    FlutterVolumeController.addListener(
      (volume) {
        if (!cameraLoaded) {
          // there is a bug, this is called at the start
          return;
        }
        if (sharePreviewIsShown) return;
        if (controller.value.isInitialized) takePicture();
      },
    );
  }

  @override
  void dispose() {
    FlutterVolumeController.removeListener();
    if (cameraId < gCameras.length) {
      controller.dispose();
    }
    super.dispose();
  }

  void selectCamera(int sCameraId, {bool init = false}) {
    if (sCameraId >= gCameras.length) return;
    if (init) {
      for (; sCameraId < gCameras.length; sCameraId++) {
        if (gCameras[sCameraId].lensDirection == CameraLensDirection.back) {
          break;
        }
      }
    }
    setState(() {
      isZoomAble = false;
    });
    controller = CameraController(gCameras[sCameraId], ResolutionPreset.high,
        enableAudio: false);
    controller.initialize().then((_) async {
      if (!mounted) {
        return;
      }
      controller.setFlashMode(isFlashOn ? FlashMode.always : FlashMode.off);

      isZoomAble = await controller.getMinZoomLevel() !=
          await controller.getMaxZoomLevel();
      setState(() {
        cameraLoaded = true;
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
    setState(() {
      cameraId = sCameraId;
    });
  }

  Future<void> updateScaleFactor(double newScale) async {
    if (scaleFactor == newScale) return;
    var minFactor = await controller.getMinZoomLevel();
    var maxFactor = await controller.getMaxZoomLevel();
    if (newScale < minFactor) {
      newScale = minFactor;
    }
    if (newScale > maxFactor) {
      newScale = maxFactor;
    }

    await controller.setZoomLevel(newScale);
    setState(() {
      scaleFactor = newScale;
    });
  }

  Future takePicture() async {
    if (isFlashOn) {
      if (isFront) {
        setState(() {
          showSelfieFlash = true;
        });
      } else {
        controller.setFlashMode(FlashMode.torch);
      }
      await Future.delayed(Duration(milliseconds: 1000));
    }

    await controller.pausePreview();
    if (!context.mounted) return;

    controller.setFlashMode(isFlashOn ? FlashMode.always : FlashMode.off);

    Future<Uint8List?> imageBytes = screenshotController.capture(pixelRatio: 1);

    setState(() {
      sharePreviewIsShown = true;
    });
    await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, a1, a2) =>
            ShareImageEditorView(imageBytes: imageBytes),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
    // does not work??
    //await controller.resumePreview();
    selectCamera(0);
    if (context.mounted) {
      setState(() {
        sharePreviewIsShown = false;
      });
    }

    setState(() {
      showSelfieFlash = false;
    });
  }

  bool get isFront =>
      controller.description.lensDirection == CameraLensDirection.front;

  @override
  Widget build(BuildContext context) {
    if (cameraId >= gCameras.length) {
      return Center(
        child: Text("No camera found."),
      );
    }
    return MediaViewSizing(
      Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                (controller.value.isInitialized)
                    ? Positioned.fill(
                        child: Screenshot(
                          controller: screenshotController,
                          child: AspectRatio(
                            aspectRatio: 9 / 16,
                            child: ClipRect(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: controller.value.previewSize!.height,
                                  height: controller.value.previewSize!.width,
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.rotationY(
                                        (isFront && Platform.isAndroid)
                                            ? 3.14
                                            : 0),
                                    child: CameraPreview(controller),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(),
                Positioned.fill(
                  child: GestureDetector(
                    onPanStart: (details) async {
                      if (isFront) {
                        return;
                      }
                      setState(() {
                        basePanY = details.localPosition.dy;
                        baseScaleFactor = scaleFactor;
                      });
                    },
                    onPanUpdate: (details) async {
                      if (isFront) {
                        return;
                      }
                      var diff = basePanY - details.localPosition.dy;
                      if (diff > 200) diff = 200;
                      if (diff < -200) diff = -200;
                      var tmp = (diff / 200 * (7 * 2)).toInt() / 2;
                      tmp = baseScaleFactor + tmp;
                      if (tmp < 1) tmp = 1;
                      updateScaleFactor(tmp);
                    },
                    onDoubleTap: () async {
                      selectCamera((cameraId + 1) % 2);
                    },
                  ),
                ),
                if (!sharePreviewIsShown)
                  Positioned(
                    right: 5,
                    top: 0,
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            ActionButton(
                              FontAwesomeIcons.repeat,
                              tooltipText:
                                  context.lang.switchFrontAndBackCamera,
                              onPressed: () async {
                                selectCamera((cameraId + 1) % 2);
                              },
                            ),
                            ActionButton(
                              FontAwesomeIcons.boltLightning,
                              tooltipText: context.lang.toggleFlashLight,
                              color: isFlashOn
                                  ? const Color.fromARGB(255, 255, 230, 0)
                                  : const Color.fromARGB(158, 255, 255, 255),
                              onPressed: () async {
                                if (isFlashOn) {
                                  controller.setFlashMode(FlashMode.off);
                                  isFlashOn = false;
                                } else {
                                  controller.setFlashMode(FlashMode.always);
                                  isFlashOn = true;
                                }
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
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
                          if (controller.value.isInitialized &&
                              isZoomAble &&
                              !isFront)
                            SizedBox(
                              width: 120,
                              child: CameraZoomButtons(
                                key: widget.key,
                                scaleFactor: scaleFactor,
                                updateScaleFactor: updateScaleFactor,
                                controller: controller,
                              ),
                            ),
                          const SizedBox(height: 30),
                          GestureDetector(
                            onTap: () async {
                              takePicture();
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
          ),
          if (showSelfieFlash)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
