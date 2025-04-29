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
import 'package:twonly/src/views/camera/components/zoom_selector.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/image_editor/action_button.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';
import 'package:twonly/src/views/components/permissions_view.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera/share_image_editor_view.dart';

class CameraPreviewView extends StatefulWidget {
  const CameraPreviewView({super.key, this.sendTo});
  final Contact? sendTo;

  @override
  State<CameraPreviewView> createState() => _CameraPreviewViewState();
}

class _CameraPreviewViewState extends State<CameraPreviewView> {
  double scaleFactor = 1;
  bool sharePreviewIsShown = false;
  bool galleryLoadedImageIsShown = false;
  bool isFlashOn = false;
  bool showSelfieFlash = false;
  int cameraId = 0;
  bool isZoomAble = false;
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

  CameraController? controller;
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    selectCamera(0, init: true);
    initAsync();
  }

  void initAsync() async {
    final user = await getUser();
    if (user == null) return;
    if (user.useHighQuality != null) {
      useHighQuality = user.useHighQuality!;
    }
    hasAudioPermission = await Permission.microphone.isGranted;
    setState(() {});
  }

  @override
  void dispose() {
    if (cameraId < gCameras.length) {
      controller?.dispose();
    }
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
      if (hasAudioPermission) {
        selectCamera(cameraId);
      }
    }
  }

  Future selectCamera(int sCameraId, {bool init = false}) async {
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
    controller = CameraController(
      gCameras[sCameraId],
      ResolutionPreset.high,
      enableAudio: await Permission.microphone.isGranted && videoWithAudio,
    );
    controller?.initialize().then((_) async {
      if (!mounted) {
        return;
      }
      await controller?.lockCaptureOrientation(DeviceOrientation.portraitUp);
      controller?.setFlashMode(isFlashOn ? FlashMode.always : FlashMode.off);

      isZoomAble = await controller?.getMinZoomLevel() !=
          await controller?.getMaxZoomLevel();
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
    if (scaleFactor == newScale || controller == null) return;
    var minFactor = await controller!.getMinZoomLevel();
    var maxFactor = await controller!.getMaxZoomLevel();
    if (newScale < minFactor) {
      newScale = minFactor;
    }
    if (newScale > maxFactor) {
      newScale = maxFactor;
    }

    await controller?.setZoomLevel(newScale);
    setState(() {
      scaleFactor = newScale;
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

    if (useHighQuality && !isFront) {
      if (Platform.isIOS) {
        await controller?.pausePreview();
        if (!context.mounted) return;
      }
      try {
        // Take the picture
        final XFile? picture = await controller?.takePicture();
        if (picture == null) return;
        imageBytes = loadAndDeletePictureFromFile(picture);
      } catch (e) {
        _showCameraException(e);
        return;
      }
    } else {
      if (isFlashOn) {
        if (isFront) {
          setState(() {
            showSelfieFlash = true;
          });
        } else {
          controller?.setFlashMode(FlashMode.torch);
        }
        await Future.delayed(Duration(milliseconds: 1000));
      }

      await controller?.pausePreview();
      if (!context.mounted) return;

      controller?.setFlashMode(isFlashOn ? FlashMode.always : FlashMode.off);
      imageBytes = screenshotController.capture(
          pixelRatio: MediaQuery.of(context).devicePixelRatio);
    }

    if (await pushMediaEditor(imageBytes, null)) {
      return;
    }
  }

  Future<bool> pushMediaEditor(
      Future<Uint8List?>? imageBytes, XFile? videoFilePath) async {
    bool? shoudReturn = await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, a1, a2) => ShareImageEditorView(
          videoFilePath: videoFilePath,
          imageBytes: imageBytes,
          sendTo: widget.sendTo,
          mirrorVideo: isFront && Platform.isAndroid,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
    if (!context.mounted) return true;
    if (shoudReturn == null) return true;
    if (shoudReturn) {
      if (!context.mounted) return true;
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      return true;
    }
    selectCamera(cameraId);
    if (context.mounted) {
      setState(() {
        sharePreviewIsShown = false;
        showSelfieFlash = false;
      });
    }
    return false;
  }

  bool get isFront =>
      controller?.description.lensDirection == CameraLensDirection.front;

  Future onPanUpdate(details) async {
    if (isFront) {
      return;
    }
    var diff = basePanY - details.localPosition.dy;

    var baseDiff = Platform.isAndroid ? 200.0 : 300.0;

    if (diff > baseDiff) diff = baseDiff;
    if (diff < -baseDiff) diff = -baseDiff;
    var tmp = 0.0;
    if (Platform.isAndroid) {
      tmp = (diff / baseDiff * (7 * 2)).toInt() / 2;
    } else {
      tmp = (diff / baseDiff * (14 * 2)).toInt() / 4;
    }

    tmp = baseScaleFactor + tmp;
    if (tmp < 1) tmp = 1;
    updateScaleFactor(tmp);
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
    if (controller != null && controller!.value.isRecordingVideo) return;

    try {
      await controller?.startVideoRecording();
      videoRecordingTimer = Timer.periodic(Duration(milliseconds: 10), (timer) {
        setState(() {
          currentTime = DateTime.now();
        });

        if (videoRecordingStarted != null &&
            currentTime.difference(videoRecordingStarted!).inSeconds >= 10) {
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
      _showCameraException(e);
      return;
    }
  }

  Future stopVideoRecording() async {
    if (videoRecordingTimer != null) {
      videoRecordingTimer?.cancel();
      videoRecordingTimer = null;
    }
    if (controller == null || !controller!.value.isRecordingVideo) {
      return null;
    }

    try {
      setState(() {
        videoRecordingStarted = null;
        isVideoRecording = false;
        sharePreviewIsShown = true;
      });
      XFile? videoPath = await controller?.stopVideoRecording();
      await controller?.pausePreview();
      if (await pushMediaEditor(null, videoPath)) {
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
    if (cameraId >= gCameras.length || controller == null) {
      return Center(
        child: Text("No camera found."),
      );
    }
    return MediaViewSizing(
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
        onDoubleTap: () async {
          selectCamera((cameraId + 1) % 2);
        },
        onLongPressMoveUpdate: onPanUpdate,
        onLongPressStart: (details) {
          setState(() {
            basePanY = details.localPosition.dy;
            baseScaleFactor = scaleFactor;
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
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  if (!galleryLoadedImageIsShown)
                    CameraPreviewWidget(
                      controller: controller!,
                      screenshotController: screenshotController,
                      isFront: isFront,
                    ),
                  if (galleryLoadedImageIsShown)
                    Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 1, color: context.color.primary),
                      ),
                    ),
                  // Positioned.fill(
                  //   child: GestureDetector(),
                  // ),
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
                                tooltipText:
                                    context.lang.switchFrontAndBackCamera,
                                onPressed: () async {
                                  selectCamera((cameraId + 1) % 2);
                                },
                              ),
                              ActionButton(
                                isFlashOn
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded,
                                tooltipText: context.lang.toggleFlashLight,
                                color: isFlashOn
                                    ? Colors.white
                                    : Colors.white.withAlpha(160),
                                onPressed: () async {
                                  if (isFlashOn) {
                                    controller?.setFlashMode(FlashMode.off);
                                    isFlashOn = false;
                                  } else {
                                    controller?.setFlashMode(FlashMode.always);
                                    isFlashOn = true;
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
                                    selectCamera(cameraId);
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
                            if (controller!.value.isInitialized &&
                                isZoomAble &&
                                !isFront &&
                                !isVideoRecording)
                              SizedBox(
                                width: 120,
                                child: CameraZoomButtons(
                                  key: widget.key,
                                  scaleFactor: scaleFactor,
                                  updateScaleFactor: updateScaleFactor,
                                  controller: controller!,
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
                ],
              ),
            ),
            if (videoRecordingStarted != null)
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Stack(
                      children: [
                        Center(
                          child: CircularProgressIndicator(
                            value:
                                (currentTime.difference(videoRecordingStarted!))
                                        .inMilliseconds /
                                    (10 * 1000),
                            strokeWidth: 4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.red),
                            backgroundColor: Colors.grey[300],
                          ),
                        ),
                        Center(
                          child: Text(
                            currentTime
                                .difference(videoRecordingStarted!)
                                .inSeconds
                                .toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              shadows: [
                                Shadow(
                                  color: const Color.fromARGB(122, 0, 0, 0),
                                  blurRadius: 5.0,
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
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

class SendToWidget extends StatelessWidget {
  final String sendTo;

  const SendToWidget({
    super.key,
    required this.sendTo,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 24,
      decoration: TextDecoration.none,
      shadows: [
        Shadow(
          color: const Color.fromARGB(122, 0, 0, 0),
          blurRadius: 5.0,
        ),
      ],
    );

    TextStyle boldTextStyle = textStyle.copyWith(
      fontWeight: FontWeight.normal,
      fontSize: 28,
    );

    return Positioned(
      right: 0,
      left: 0,
      top: 50,
      child: Column(
        children: [
          Text(
            context.lang.cameraPreviewSendTo,
            textAlign: TextAlign.center,
            style: textStyle,
          ),
          Text(
            sendTo,
            textAlign: TextAlign.center,
            style: boldTextStyle, // Use the bold text style here
          ),
        ],
      ),
    );
  }

  String getContactDisplayName(String contact) {
    // Replace this with your actual logic to get the contact display name
    return contact; // Placeholder implementation
  }
}

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  final ScreenshotController screenshotController;
  final bool isFront;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.screenshotController,
    required this.isFront,
  });

  @override
  Widget build(BuildContext context) {
    return (controller.value.isInitialized)
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
                            (isFront && Platform.isAndroid) ? 3.14 : 0),
                        child: CameraPreview(controller),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        : Container();
  }
}

class CameraPreviewViewPermission extends StatefulWidget {
  const CameraPreviewViewPermission({super.key, this.sendTo});
  final Contact? sendTo;

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
              return CameraPreviewView(sendTo: widget.sendTo);
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
