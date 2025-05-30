import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/views/camera/camera_preview_components/send_to.dart';
import 'package:twonly/src/views/camera/camera_preview_components/video_recording_time.dart';
import 'package:twonly/src/views/camera/camera_preview_components/zoom_selector.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/camera_send_to_view.dart';
import 'package:twonly/src/views/camera/image_editor/action_button.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';
import 'package:twonly/src/views/camera/camera_preview_components/permissions_view.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera/share_image_editor_view.dart';
import 'package:twonly/src/views/home.view.dart';

int maxVideoRecordingTime = 15;

Future<(SelectedCameraDetails, CameraController)?> initializeCameraController(
    SelectedCameraDetails details,
    int sCameraId,
    bool init,
    bool enableAudio) async {
  if (sCameraId >= gCameras.length) return null;
  if (init) {
    for (; sCameraId < gCameras.length; sCameraId++) {
      if (gCameras[sCameraId].lensDirection == CameraLensDirection.back) {
        break;
      }
    }
  }
  details.isZoomAble = false;
  if (details.cameraId != sCameraId) {
    // switch between front and back
    details.scaleFactor = 1;
  }

  CameraController cameraController = CameraController(
    gCameras[sCameraId],
    ResolutionPreset.high,
    enableAudio: enableAudio,
  );

  await cameraController.initialize().then((_) async {
    await cameraController.setZoomLevel(details.scaleFactor);
    await cameraController.lockCaptureOrientation(DeviceOrientation.portraitUp);
    cameraController
        .setFlashMode(details.isFlashOn ? FlashMode.always : FlashMode.off);
    await cameraController
        .getMaxZoomLevel()
        .then((double value) => details.maxAvailableZoom = value);
    await cameraController
        .getMinZoomLevel()
        .then((double value) => details.minAvailableZoom = value);
    details.isZoomAble = details.maxAvailableZoom != details.minAvailableZoom;
    details.cameraLoaded = true;
    details.cameraId = sCameraId;
  }).catchError((Object e) {
    Logger("camera_preview.dart").shout("$e");
  });
  return (details, cameraController);
}

class SelectedCameraDetails {
  double maxAvailableZoom = 1;
  double minAvailableZoom = 1;
  int cameraId = 0;
  bool isZoomAble = false;
  bool isFlashOn = false;
  double scaleFactor = 1;
  bool cameraLoaded = false;
}

class CameraPreviewControllerView extends StatefulWidget {
  const CameraPreviewControllerView({
    super.key,
    required this.selectCamera,
    required this.isHomeView,
    this.sendTo,
  });
  final Contact? sendTo;
  final Function(int sCameraId, bool init, bool enableAudio) selectCamera;
  final bool isHomeView;

  @override
  State<CameraPreviewControllerView> createState() =>
      _CameraPreviewControllerView();
}

class _CameraPreviewControllerView extends State<CameraPreviewControllerView> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: checkPermissions(),
      builder: (context, snap) {
        if (snap.hasData) {
          if (snap.data!) {
            return CameraPreviewView(
              sendTo: widget.sendTo,
              selectCamera: widget.selectCamera,
              isHomeView: widget.isHomeView,
            );
          } else {
            return PermissionHandlerView(onSuccess: () {
              setState(() {});
            });
          }
        } else {
          return Container();
        }
      },
    );
  }
}

class CameraPreviewView extends StatefulWidget {
  const CameraPreviewView(
      {super.key,
      this.sendTo,
      required this.selectCamera,
      required this.isHomeView});
  final Contact? sendTo;
  final bool isHomeView;
  final Function(int sCameraId, bool init, bool enableAudio) selectCamera;

  @override
  State<CameraPreviewView> createState() => _CameraPreviewViewState();
}

class _CameraPreviewViewState extends State<CameraPreviewView> {
  bool sharePreviewIsShown = false;
  bool galleryLoadedImageIsShown = false;
  bool showSelfieFlash = false;
  double basePanY = 0;
  double baseScaleFactor = 0;
  bool cameraLoaded = false;
  bool useHighQuality = false;
  bool isVideoRecording = false;
  bool hasAudioPermission = true;
  bool videoWithAudio = true;
  DateTime? videoRecordingStarted;
  Timer? videoRecordingTimer;

  DateTime currentTime = DateTime.now();
  final GlobalKey keyTriggerButton = GlobalKey();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // selectCamera(0, init: true);
    initAsync();
  }

  CameraController? get cameraController => widget.isHomeView
      ? HomeViewState.cameraController
      : CameraSendToViewState.cameraController;

  SelectedCameraDetails get selectedCameraDetails => widget.isHomeView
      ? HomeViewState.selectedCameraDetails
      : CameraSendToViewState.selectedCameraDetails;

  ScreenshotController get screenshotController => widget.isHomeView
      ? HomeViewState.screenshotController
      : CameraSendToViewState.screenshotController;

  void initAsync() async {
    final user = await getUser();
    if (user == null) return;
    if (user.useHighQuality != null) {
      useHighQuality = user.useHighQuality!;
    }
    hasAudioPermission = await Permission.microphone.isGranted;
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    videoRecordingTimer?.cancel();
    super.dispose();
  }

  Future requestMicrophonePermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
    ].request();
    if (statuses[Permission.microphone]!.isPermanentlyDenied) {
      openAppSettings();
    } else {
      hasAudioPermission = await Permission.microphone.isGranted;
      setState(() {});
    }
  }

  Future<void> updateScaleFactor(double newScale) async {
    if (selectedCameraDetails.scaleFactor == newScale ||
        cameraController == null) {
      return;
    }
    await cameraController?.setZoomLevel(newScale.clamp(
        selectedCameraDetails.minAvailableZoom,
        selectedCameraDetails.maxAvailableZoom));
    setState(() {
      selectedCameraDetails.scaleFactor = newScale;
    });
  }

  Future<Uint8List?> loadAndDeletePictureFromFile(XFile picture) async {
    try {
      // Load the image into bytes
      final Uint8List imageBytes = await picture.readAsBytes();
      // Remove the image file
      await File(picture.path).delete();
      return imageBytes;
    } catch (e) {
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading picture: $e'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return null;
    }
  }

  Future takePicture() async {
    if (sharePreviewIsShown || isVideoRecording) return;
    late Future<Uint8List?> imageBytes;

    setState(() {
      sharePreviewIsShown = true;
    });
    if (selectedCameraDetails.isFlashOn) {
      if (isFront) {
        setState(() {
          showSelfieFlash = true;
        });
      } else {
        cameraController?.setFlashMode(FlashMode.torch);
      }
      await Future.delayed(Duration(milliseconds: 1000));
    }

    await cameraController?.pausePreview();
    if (!mounted) return;

    cameraController?.setFlashMode(
        selectedCameraDetails.isFlashOn ? FlashMode.always : FlashMode.off);
    imageBytes = screenshotController.capture(
        pixelRatio:
            (useHighQuality) ? MediaQuery.of(context).devicePixelRatio : 1);

    if (await pushMediaEditor(imageBytes, null)) {
      return;
    }
  }

  Future<bool> pushMediaEditor(
      Future<Uint8List?>? imageBytes, File? videoFilePath) async {
    bool? shouldReturn = await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, a1, a2) => ShareImageEditorView(
          videoFilePath: videoFilePath,
          imageBytes: imageBytes,
          sendTo: widget.sendTo,
          mirrorVideo: isFront && Platform.isAndroid,
          useHighQuality: useHighQuality,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
    if (mounted) {
      setState(() {
        sharePreviewIsShown = false;
        showSelfieFlash = false;
      });
    }
    if (!mounted) return true;
    // shouldReturn is null when the user used the back button
    if (shouldReturn != null && shouldReturn) {
      // ignore: use_build_context_synchronously
      if (widget.sendTo == null) {
        globalUpdateOfHomeViewPageIndex(0);
      } else {
        Navigator.pop(context);
      }
      return true;
    }
    widget.selectCamera(selectedCameraDetails.cameraId, false, false);
    return false;
  }

  bool get isFront =>
      cameraController?.description.lensDirection == CameraLensDirection.front;

  Future onPanUpdate(details) async {
    if (isFront) {
      return;
    }
    if (cameraController == null) return;
    if (!cameraController!.value.isInitialized) return;

    selectedCameraDetails.scaleFactor =
        (baseScaleFactor + (basePanY - details.localPosition.dy) / 30)
            .clamp(1, selectedCameraDetails.maxAvailableZoom);

    await cameraController!.setZoomLevel(selectedCameraDetails.scaleFactor);
    if (mounted) {
      setState(() {});
    }
  }

  Future pickImageFromGallery() async {
    setState(() {
      galleryLoadedImageIsShown = true;
      sharePreviewIsShown = true;
    });
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      if (await pushMediaEditor(imageFile.readAsBytes(), null)) {
        return;
      }
    }
    setState(() {
      galleryLoadedImageIsShown = false;
      sharePreviewIsShown = false;
    });
  }

  Future startVideoRecording() async {
    if (cameraController != null && cameraController!.value.isRecordingVideo) {
      return;
    }
    if (hasAudioPermission && videoWithAudio) {
      await widget.selectCamera(
        selectedCameraDetails.cameraId,
        false,
        await Permission.microphone.isGranted && videoWithAudio,
      );
    }

    setState(() {
      isVideoRecording = true;
    });

    try {
      await cameraController?.startVideoRecording();
      videoRecordingTimer = Timer.periodic(Duration(milliseconds: 15), (timer) {
        setState(() {
          currentTime = DateTime.now();
        });
        if (videoRecordingStarted != null &&
            currentTime.difference(videoRecordingStarted!).inSeconds >=
                maxVideoRecordingTime) {
          timer.cancel();
          videoRecordingTimer = null;
          stopVideoRecording();
        }
      });
      setState(() {
        videoRecordingStarted = DateTime.now();
        isVideoRecording = true;
      });
    } on CameraException catch (e) {
      setState(() {
        isVideoRecording = false;
      });
      _showCameraException(e);
      return;
    }
  }

  Future stopVideoRecording() async {
    if (videoRecordingTimer != null) {
      videoRecordingTimer?.cancel();
      videoRecordingTimer = null;
    }
    if (cameraController == null || !cameraController!.value.isRecordingVideo) {
      return null;
    }

    try {
      setState(() {
        videoRecordingStarted = null;
        isVideoRecording = false;
        sharePreviewIsShown = true;
      });
      File? videoPathFile;
      XFile? videoPath = await cameraController?.stopVideoRecording();
      if (videoPath != null) {
        if (Platform.isAndroid) {
          // see https://github.com/flutter/flutter/issues/148335
          await File(videoPath.path).rename("${videoPath.path}.mp4");
          videoPathFile = File("${videoPath.path}.mp4");
        } else {
          videoPathFile = File(videoPath.path);
        }
      }
      await cameraController?.pausePreview();
      if (await pushMediaEditor(null, videoPathFile)) {
        return;
      }
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(dynamic e) {
    Logger("ui.camera").shout("$e");
    try {
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (selectedCameraDetails.cameraId >= gCameras.length ||
        cameraController == null) {
      return Container();
    }
    return MediaViewSizing(
      child: GestureDetector(
        onPanStart: (details) async {
          if (isFront) {
            return;
          }
          setState(() {
            basePanY = details.localPosition.dy;
            baseScaleFactor = selectedCameraDetails.scaleFactor;
          });
        },
        onLongPressMoveUpdate: onPanUpdate,
        onLongPressStart: (details) {
          setState(() {
            basePanY = details.localPosition.dy;
            baseScaleFactor = selectedCameraDetails.scaleFactor;
          });
          // Get the position of the pointer
          RenderBox renderBox =
              keyTriggerButton.currentContext?.findRenderObject() as RenderBox;
          Offset localPosition =
              renderBox.globalToLocal(details.globalPosition);

          final containerRect =
              Rect.fromLTWH(0, 0, renderBox.size.width, renderBox.size.height);

          if (containerRect.contains(localPosition)) {
            startVideoRecording();
          }
        },
        onLongPressEnd: (a) {
          stopVideoRecording();
        },
        onPanEnd: (a) {
          stopVideoRecording();
        },
        onPanUpdate: onPanUpdate,
        child: Stack(
          children: [
            if (galleryLoadedImageIsShown)
              Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 1, color: context.color.primary),
                ),
              ),
            if (!sharePreviewIsShown &&
                widget.sendTo != null &&
                !isVideoRecording)
              SendToWidget(sendTo: getContactDisplayName(widget.sendTo!)),
            if (!sharePreviewIsShown && !isVideoRecording)
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
                          Icons.repeat_rounded,
                          tooltipText: context.lang.switchFrontAndBackCamera,
                          onPressed: () async {
                            widget.selectCamera(
                                (selectedCameraDetails.cameraId + 1) % 2,
                                false,
                                false);
                          },
                        ),
                        ActionButton(
                          selectedCameraDetails.isFlashOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          tooltipText: context.lang.toggleFlashLight,
                          color: selectedCameraDetails.isFlashOn
                              ? Colors.white
                              : Colors.white.withAlpha(160),
                          onPressed: () async {
                            if (selectedCameraDetails.isFlashOn) {
                              cameraController?.setFlashMode(FlashMode.off);
                              selectedCameraDetails.isFlashOn = false;
                            } else {
                              cameraController?.setFlashMode(FlashMode.always);
                              selectedCameraDetails.isFlashOn = true;
                            }
                            setState(() {});
                          },
                        ),
                        if (!isFront)
                          ActionButton(
                            Icons.hd_rounded,
                            tooltipText: context.lang.toggleHighQuality,
                            color: useHighQuality
                                ? Colors.white
                                : Colors.white.withAlpha(160),
                            onPressed: () async {
                              useHighQuality = !useHighQuality;
                              setState(() {});
                              var user = await getUser();
                              if (user != null) {
                                user.useHighQuality = useHighQuality;
                                updateUser(user);
                              }
                            },
                          ),
                        if (!hasAudioPermission)
                          ActionButton(
                            Icons.mic_off_rounded,
                            color: Colors.white.withAlpha(160),
                            tooltipText:
                                "Allow microphone access for video recording.",
                            onPressed: requestMicrophonePermission,
                          ),
                        if (hasAudioPermission)
                          ActionButton(
                            (videoWithAudio)
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            tooltipText: "Record video with audio.",
                            color: (videoWithAudio)
                                ? Colors.white
                                : Colors.white.withAlpha(160),
                            onPressed: () async {
                              setState(() {
                                videoWithAudio = !videoWithAudio;
                              });
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
                      if (cameraController!.value.isInitialized &&
                          selectedCameraDetails.isZoomAble &&
                          !isFront &&
                          !isVideoRecording)
                        SizedBox(
                          width: 120,
                          child: CameraZoomButtons(
                            key: widget.key,
                            scaleFactor: selectedCameraDetails.scaleFactor,
                            updateScaleFactor: updateScaleFactor,
                            controller: cameraController!,
                          ),
                        ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (!isVideoRecording)
                            GestureDetector(
                              onTap: pickImageFromGallery,
                              child: Align(
                                alignment: Alignment.center,
                                child: Container(
                                  height: 50,
                                  width: 80,
                                  padding: const EdgeInsets.all(2),
                                  child: Center(
                                    child: FaIcon(
                                      FontAwesomeIcons.photoFilm,
                                      color: Colors.white,
                                      size: 25,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          GestureDetector(
                            onTap: takePicture,
                            // onLongPress: startVideoRecording,
                            key: keyTriggerButton,
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
                                    color: isVideoRecording
                                        ? Colors.red
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (!isVideoRecording) SizedBox(width: 80)
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            VideoRecordingTimer(
              videoRecordingStarted: videoRecordingStarted,
              maxVideoRecordingTime: maxVideoRecordingTime,
            ),
            if (!sharePreviewIsShown && widget.sendTo != null)
              Positioned(
                left: 5,
                top: 10,
                child: ActionButton(
                  FontAwesomeIcons.xmark,
                  tooltipText: context.lang.close,
                  onPressed: () async {
                    Navigator.pop(context);
                  },
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
      ),
    );
  }
}
