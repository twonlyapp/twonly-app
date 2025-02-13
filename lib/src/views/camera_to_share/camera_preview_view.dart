import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
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
  double _lastZoom = 1;
  double _basePanY = 0;
  bool sharePreviewIsShown = false;
  bool isFlashOn = false;
  bool showSelfieFlash = false;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MediaViewSizing(
      Stack(
        children: [
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
                        debugPrint("Delete ${single.path!}");
                        File(single.path!).delete();
                        setState(() {
                          sharePreviewIsShown = true;
                        });
                        await Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (context, a1, a2) =>
                                ShareImageEditorView(imageBytes: imageBytes),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return child;
                            },
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                        if (context.mounted) {
                          setState(() {
                            sharePreviewIsShown = false;
                          });
                        }
                      },
                      multiple: (multiple) {
                        multiple.fileBySensor.forEach((key, value) {
                          debugPrint(
                              'multiple image taken: $key ${value?.path}');
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
                          debugPrint(
                              'multiple video taken: $key ${value?.path}');
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
                            aspectRatio: CameraAspectRatios.ratio_16_9,
                            flash: isFlashOn ? FlashMode.on : FlashMode.none,
                          );
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
                                    cameraState.switchCameraSensor(
                                      aspectRatio:
                                          CameraAspectRatios.ratio_16_9,
                                      flash: isFlashOn
                                          ? FlashMode.on
                                          : FlashMode.none,
                                    );
                                  },
                                ),
                                ActionButton(
                                  FontAwesomeIcons.boltLightning,
                                  tooltipText: context.lang.toggleFlashLight,
                                  color: isFlashOn
                                      ? const Color.fromARGB(255, 255, 230, 0)
                                      : const Color.fromARGB(
                                          158, 255, 255, 255),
                                  onPressed: () async {
                                    if (isFlashOn) {
                                      cameraState.sensorConfig
                                          .setFlashMode(FlashMode.none);
                                      isFlashOn = false;
                                    } else {
                                      cameraState.sensorConfig
                                          .setFlashMode(FlashMode.on);
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
                              AwesomeZoomSelector(state: cameraState),
                              const SizedBox(height: 30),
                              GestureDetector(
                                onTap: () async {
                                  if (cameraState.sensorConfig.flashMode ==
                                          FlashMode.on &&
                                      cameraState.sensorConfig.sensors.first
                                              .position ==
                                          SensorPosition.front) {
                                    setState(() {
                                      showSelfieFlash = true;
                                    });
                                    await Future.delayed(
                                        Duration(milliseconds: 500));
                                  }
                                  cameraState.when(
                                      onPhotoMode: (picState) =>
                                          picState.takePhoto());
                                  setState(() {
                                    showSelfieFlash = false;
                                  });
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
                },
              ),
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
          if (sharePreviewIsShown)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 100.0,
                  sigmaY: 100.0,
                ),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            )
        ],
      ),
    );
  }
}
