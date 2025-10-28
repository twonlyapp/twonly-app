import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera/camera_preview_components/permissions_view.dart';
import 'package:twonly/src/views/camera/camera_preview_components/send_to.dart';
import 'package:twonly/src/views/camera/camera_preview_components/video_recording_time.dart';
import 'package:twonly/src/views/camera/camera_preview_components/zoom_selector.dart';
import 'package:twonly/src/views/camera/image_editor/action_button.dart';
import 'package:twonly/src/views/camera/share_image_editor_view.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';
import 'package:twonly/src/views/home.view.dart';

int maxVideoRecordingTime = 60;

Future<(SelectedCameraDetails, CameraController)?> initializeCameraController(
  SelectedCameraDetails details,
  int sCameraId,
  bool init,
) async {
  var cameraId = sCameraId;
  if (cameraId >= gCameras.length) return null;
  if (init) {
    for (; cameraId < gCameras.length; cameraId++) {
      if (gCameras[cameraId].lensDirection == CameraLensDirection.back) {
        break;
      }
    }
  }
  details.isZoomAble = false;
  if (details.cameraId != cameraId) {
    // switch between front and back
    details.scaleFactor = 1;
  }

  final cameraController = CameraController(
    gCameras[cameraId],
    ResolutionPreset.high,
    enableAudio: await Permission.microphone.isGranted,
  );

  await cameraController.initialize().then((_) async {
    await cameraController.setZoomLevel(details.scaleFactor);
    await cameraController.lockCaptureOrientation(DeviceOrientation.portraitUp);
    await cameraController
        .setFlashMode(details.isFlashOn ? FlashMode.always : FlashMode.off);
    await cameraController
        .getMaxZoomLevel()
        .then((double value) => details.maxAvailableZoom = value);
    await cameraController
        .getMinZoomLevel()
        .then((double value) => details.minAvailableZoom = value);
    details
      ..isZoomAble = details.maxAvailableZoom != details.minAvailableZoom
      ..cameraLoaded = true
      ..cameraId = cameraId;
  }).catchError((Object e) {
    Log.error('$e');
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

class CameraPreviewControllerView extends StatelessWidget {
  const CameraPreviewControllerView({
    required this.cameraController,
    required this.selectCamera,
    required this.selectedCameraDetails,
    required this.screenshotController,
    super.key,
    this.sendToGroup,
  });
  final Group? sendToGroup;
  final Future<CameraController?> Function(int sCameraId, bool init)
      selectCamera;
  final CameraController? cameraController;
  final SelectedCameraDetails selectedCameraDetails;
  final ScreenshotController screenshotController;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: checkPermissions(),
      builder: (context, snap) {
        if (snap.hasData) {
          if (snap.data!) {
            return CameraPreviewView(
              sendToGroup: sendToGroup,
              selectCamera: selectCamera,
              cameraController: cameraController,
              selectedCameraDetails: selectedCameraDetails,
              screenshotController: screenshotController,
            );
          } else {
            return PermissionHandlerView(
              onSuccess: () {
                selectCamera(0, true);
              },
            );
          }
        } else {
          return Container();
        }
      },
    );
  }
}

class CameraPreviewView extends StatefulWidget {
  const CameraPreviewView({
    required this.selectCamera,
    required this.cameraController,
    required this.selectedCameraDetails,
    required this.screenshotController,
    super.key,
    this.sendToGroup,
  });
  final Group? sendToGroup;
  final Future<CameraController?> Function(
    int sCameraId,
    bool init,
  ) selectCamera;
  final CameraController? cameraController;
  final SelectedCameraDetails selectedCameraDetails;
  final ScreenshotController screenshotController;

  @override
  State<CameraPreviewView> createState() => _CameraPreviewViewState();
}

class _CameraPreviewViewState extends State<CameraPreviewView> {
  bool _sharePreviewIsShown = false;
  bool _galleryLoadedImageIsShown = false;
  bool _showSelfieFlash = false;
  double _basePanY = 0;
  double _baseScaleFactor = 0;
  bool _isVideoRecording = false;
  bool _hasAudioPermission = true;
  DateTime? _videoRecordingStarted;
  Timer? _videoRecordingTimer;

  DateTime _currentTime = DateTime.now();
  final GlobalKey keyTriggerButton = GlobalKey();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    _hasAudioPermission = await Permission.microphone.isGranted;

    if (!_hasAudioPermission && !gUser.requestedAudioPermission) {
      await updateUserdata((u) {
        u.requestedAudioPermission = true;
        return u;
      });
      await requestMicrophonePermission();
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _videoRecordingTimer?.cancel();
    super.dispose();
  }

  Future<void> requestMicrophonePermission() async {
    final statuses = await [
      Permission.microphone,
    ].request();
    if (statuses[Permission.microphone]!.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      _hasAudioPermission = await Permission.microphone.isGranted;
      setState(() {});
    }
  }

  Future<void> updateScaleFactor(double newScale) async {
    if (widget.selectedCameraDetails.scaleFactor == newScale ||
        widget.cameraController == null) {
      return;
    }
    await widget.cameraController?.setZoomLevel(
      newScale.clamp(
        widget.selectedCameraDetails.minAvailableZoom,
        widget.selectedCameraDetails.maxAvailableZoom,
      ),
    );
    setState(() {
      widget.selectedCameraDetails.scaleFactor = newScale;
    });
  }

  Future<Uint8List?> loadAndDeletePictureFromFile(XFile picture) async {
    try {
      // Load the image into bytes
      final imageBytes = await picture.readAsBytes();
      // Remove the image file
      await File(picture.path).delete();
      return imageBytes;
    } catch (e) {
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading picture: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return null;
    }
  }

  Future<void> takePicture() async {
    if (_sharePreviewIsShown || _isVideoRecording) return;
    late Future<Uint8List?> imageBytes;

    setState(() {
      _sharePreviewIsShown = true;
    });
    if (widget.selectedCameraDetails.isFlashOn) {
      if (isFront) {
        setState(() {
          _showSelfieFlash = true;
        });
      } else {
        await widget.cameraController?.setFlashMode(FlashMode.torch);
      }
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    await widget.cameraController?.pausePreview();
    if (!mounted) {
      return;
    }

    if (Platform.isIOS) {
      // android has a problem with this. Flash is turned off in the pausePreview function.
      await widget.cameraController?.setFlashMode(FlashMode.off);
    }
    if (!mounted) {
      return;
    }

    imageBytes = widget.screenshotController
        .capture(pixelRatio: MediaQuery.of(context).devicePixelRatio);

    if (await pushMediaEditor(imageBytes, null)) {
      return;
    }
    setState(() {
      _sharePreviewIsShown = false;
    });
  }

  Future<bool> pushMediaEditor(
    Future<Uint8List?>? imageBytes,
    File? videoFilePath, {
    bool sharedFromGallery = false,
  }) async {
    final mediaFileService = await initializeMediaUpload(
      (videoFilePath != null) ? MediaType.video : MediaType.image,
      gUser.defaultShowTime,
    );
    if (!mounted) return true;

    if (mediaFileService == null) {
      Log.error('Could not generate media file service');
      return false;
    }

    if (videoFilePath != null) {
      videoFilePath
        ..copySync(mediaFileService.originalPath.path)
        ..deleteSync();

      // Start with compressing the video, to speed up the process in case the video is not changed.
      // unawaited(mediaFileService.compressMedia());
    }

    final shouldReturn = await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, a1, a2) => ShareImageEditorView(
          imageBytesFuture: imageBytes,
          sharedFromGallery: sharedFromGallery,
          sendToGroup: widget.sendToGroup,
          mediaFileService: mediaFileService,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ) as bool?;
    if (mounted) {
      setState(() {
        _sharePreviewIsShown = false;
        _showSelfieFlash = false;
      });
    }
    if (!mounted) return true;
    // shouldReturn is null when the user used the back button
    if (shouldReturn != null && shouldReturn) {
      if (widget.sendToGroup == null) {
        globalUpdateOfHomeViewPageIndex(0);
      } else {
        Navigator.pop(context);
      }
      return true;
    }
    await widget.selectCamera(
      widget.selectedCameraDetails.cameraId,
      false,
    );
    return false;
  }

  bool get isFront =>
      widget.cameraController?.description.lensDirection ==
      CameraLensDirection.front;

  Future<void> onPanUpdate(dynamic details) async {
    if (isFront || details == null) {
      return;
    }
    if (widget.cameraController == null ||
        !widget.cameraController!.value.isInitialized) {
      return;
    }

    widget.selectedCameraDetails.scaleFactor = (_baseScaleFactor +
            // ignore: avoid_dynamic_calls
            (_basePanY - (details.localPosition.dy as double)) / 30)
        .clamp(1, widget.selectedCameraDetails.maxAvailableZoom);

    await widget.cameraController!
        .setZoomLevel(widget.selectedCameraDetails.scaleFactor);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> pickImageFromGallery() async {
    setState(() {
      _galleryLoadedImageIsShown = true;
      _sharePreviewIsShown = true;
    });
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      await pushMediaEditor(
        imageFile.readAsBytes(),
        null,
        sharedFromGallery: true,
      );
    }
    setState(() {
      _galleryLoadedImageIsShown = false;
      _sharePreviewIsShown = false;
    });
  }

  Future<void> startVideoRecording() async {
    if (widget.cameraController != null &&
        widget.cameraController!.value.isRecordingVideo) {
      return;
    }
    setState(() {
      _isVideoRecording = true;
    });

    try {
      await widget.cameraController?.startVideoRecording();
      _videoRecordingTimer =
          Timer.periodic(const Duration(milliseconds: 15), (timer) {
        setState(() {
          _currentTime = DateTime.now();
        });
        if (_videoRecordingStarted != null &&
            _currentTime.difference(_videoRecordingStarted!).inSeconds >=
                maxVideoRecordingTime) {
          timer.cancel();
          _videoRecordingTimer = null;
          stopVideoRecording();
        }
      });
      setState(() {
        _videoRecordingStarted = DateTime.now();
        _isVideoRecording = true;
      });
    } on CameraException catch (e) {
      setState(() {
        _isVideoRecording = false;
      });
      _showCameraException(e);
      return;
    }
  }

  Future<void> stopVideoRecording() async {
    if (_videoRecordingTimer != null) {
      _videoRecordingTimer?.cancel();
      _videoRecordingTimer = null;
    }

    setState(() {
      _videoRecordingStarted = null;
      _isVideoRecording = false;
    });

    if (widget.cameraController == null ||
        !widget.cameraController!.value.isRecordingVideo) {
      return;
    }

    setState(() {
      _sharePreviewIsShown = true;
    });

    try {
      final videoPath = await widget.cameraController?.stopVideoRecording();
      if (videoPath == null) return;
      await widget.cameraController?.pausePreview();
      if (await pushMediaEditor(null, File(videoPath.path))) {
        return;
      }
    } on CameraException catch (e) {
      _showCameraException(e);
      return;
    }
  }

  void _showCameraException(dynamic e) {
    Log.error('$e');
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedCameraDetails.cameraId >= gCameras.length ||
        widget.cameraController == null) {
      return Container();
    }
    return MediaViewSizing(
      child: GestureDetector(
        onPanStart: (details) async {
          if (isFront) {
            return;
          }
          setState(() {
            _basePanY = details.localPosition.dy;
            _baseScaleFactor = widget.selectedCameraDetails.scaleFactor;
          });
        },
        onLongPressMoveUpdate: onPanUpdate,
        onLongPressStart: (details) {
          setState(() {
            _basePanY = details.localPosition.dy;
            _baseScaleFactor = widget.selectedCameraDetails.scaleFactor;
          });
          // Get the position of the pointer
          final renderBox =
              keyTriggerButton.currentContext!.findRenderObject()! as RenderBox;
          final localPosition = renderBox.globalToLocal(details.globalPosition);

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
            if (_galleryLoadedImageIsShown)
              Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                    color: context.color.primary,
                  ),
                ),
              ),
            if (!_sharePreviewIsShown &&
                widget.sendToGroup != null &&
                !_isVideoRecording)
              SendToWidget(sendTo: widget.sendToGroup!.groupName),
            if (!_sharePreviewIsShown && !_isVideoRecording)
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
                            await widget.selectCamera(
                              (widget.selectedCameraDetails.cameraId + 1) % 2,
                              false,
                            );
                          },
                        ),
                        ActionButton(
                          widget.selectedCameraDetails.isFlashOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          tooltipText: context.lang.toggleFlashLight,
                          color: widget.selectedCameraDetails.isFlashOn
                              ? Colors.white
                              : Colors.white.withAlpha(160),
                          onPressed: () async {
                            if (widget.selectedCameraDetails.isFlashOn) {
                              await widget.cameraController
                                  ?.setFlashMode(FlashMode.off);
                              widget.selectedCameraDetails.isFlashOn = false;
                            } else {
                              await widget.cameraController
                                  ?.setFlashMode(FlashMode.always);
                              widget.selectedCameraDetails.isFlashOn = true;
                            }
                            setState(() {});
                          },
                        ),
                        if (!_hasAudioPermission)
                          ActionButton(
                            Icons.mic_off_rounded,
                            color: Colors.white.withAlpha(160),
                            tooltipText:
                                'Allow microphone access for video recording.',
                            onPressed: requestMicrophonePermission,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!_sharePreviewIsShown)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    children: [
                      if (widget.cameraController!.value.isInitialized &&
                          widget.selectedCameraDetails.isZoomAble &&
                          !isFront &&
                          !_isVideoRecording)
                        SizedBox(
                          width: 120,
                          child: CameraZoomButtons(
                            key: widget.key,
                            scaleFactor:
                                widget.selectedCameraDetails.scaleFactor,
                            updateScaleFactor: updateScaleFactor,
                            selectCamera: widget.selectCamera,
                            selectedCameraDetails: widget.selectedCameraDetails,
                            controller: widget.cameraController!,
                          ),
                        ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_isVideoRecording)
                            GestureDetector(
                              onTap: pickImageFromGallery,
                              child: Align(
                                child: Container(
                                  height: 50,
                                  width: 80,
                                  padding: const EdgeInsets.all(2),
                                  child: const Center(
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
                              child: Container(
                                height: 100,
                                width: 100,
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    width: 7,
                                    color: _isVideoRecording
                                        ? Colors.red
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (!_isVideoRecording) const SizedBox(width: 80),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            VideoRecordingTimer(
              videoRecordingStarted: _videoRecordingStarted,
              maxVideoRecordingTime: maxVideoRecordingTime,
            ),
            if (!_sharePreviewIsShown && widget.sendToGroup != null)
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
            if (_showSelfieFlash)
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
