import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:clock/clock.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_android_volume_keydown/flutter_android_volume_keydown.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/mediafiles/upload.api.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/helpers/media_view_sizing.helper.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview_controller_components/camera_bottom_controls.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview_controller_components/camera_scanned_overlay.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview_controller_components/camera_selfie_flash.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview_controller_components/camera_top_actions.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/face_filters.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/main_camera_controller.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/permissions_view.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/send_to.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/video_recording_time.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor.view.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/action_button.dart';
import 'package:twonly/src/visual/views/home.view.dart';

int maxVideoRecordingTime = 60;

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
    required this.mainController,
    required this.isVisible,
    this.hideControllers = false,
    super.key,
    this.sendToGroup,
  });

  final MainCameraController mainController;
  final Group? sendToGroup;
  final bool isVisible;
  final bool hideControllers;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: checkPermissions(),
      builder: (context, snap) {
        if (snap.hasData) {
          if (snap.data!) {
            return CameraPreviewView(
              sendToGroup: sendToGroup,
              mainCameraController: mainController,
              isVisible: isVisible,
              hideControllers: hideControllers,
            );
          } else {
            return PermissionHandlerView(
              onSuccess: () {
                mainController.selectCamera(0, true);
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
    required this.mainCameraController,
    required this.isVisible,
    required this.hideControllers,
    super.key,
    this.sendToGroup,
  });

  final MainCameraController mainCameraController;
  final Group? sendToGroup;
  final bool isVisible;
  final bool hideControllers;

  @override
  State<CameraPreviewView> createState() => _CameraPreviewViewState();
}

class _CameraPreviewViewState extends State<CameraPreviewView> {
  bool _galleryLoadedImageIsShown = false;
  bool _showSelfieFlash = false;
  double _basePanY = 0;
  double _baseScaleFactor = 0;
  bool _hasAudioPermission = true;
  DateTime? _videoRecordingStarted;
  Timer? _videoRecordingTimer;

  DateTime _currentTime = clock.now();
  final GlobalKey keyTriggerButton = GlobalKey();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  MainCameraController get mc => widget.mainCameraController;

  StreamSubscription<HardwareButton>? androidVolumeDownSub;

  @override
  void initState() {
    super.initState();
    initVolumeControl();
    initAsync();
  }

  @override
  void didUpdateWidget(covariant CameraPreviewView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        initVolumeControl();
      } else {
        _deInitVolumeControl();
      }
    }
  }

  @override
  void dispose() {
    _videoRecordingTimer?.cancel();
    _deInitVolumeControl();
    super.dispose();
  }

  Future<void> initVolumeControl() async {
    if (Platform.isIOS) {
      await FlutterVolumeController.updateShowSystemUI(false);
      double? startedVolume;

      FlutterVolumeController.addListener(
        (volume) async {
          if (!widget.isVisible) {
            await _deInitVolumeControl();
            return;
          }
          if (startedVolume == null) {
            startedVolume = volume;
            return;
          }
          if (startedVolume == volume) {
            return;
          }
          // reset the volume back to the original value
          await FlutterVolumeController.setVolume(startedVolume!);
          await takePicture();
        },
      );
    }
    if (Platform.isAndroid) {
      if ((await DeviceInfoPlugin().androidInfo).version.release == '9') {
        // MissingPluginException: MissingPluginException(No implementation found for method cancel on channel dart-tools.dev/flutter_…
        // Maybe this is the reason?
        return;
      } else {
        androidVolumeDownSub = FlutterAndroidVolumeKeydown.stream.listen((
          event,
        ) {
          if (widget.isVisible) {
            takePicture();
          } else {
            _deInitVolumeControl();
            return;
          }
        });
      }
    }
  }

  Future<void> _deInitVolumeControl() async {
    if (Platform.isIOS) {
      await FlutterVolumeController.updateShowSystemUI(true);
      FlutterVolumeController.removeListener();
    }
    if (Platform.isAndroid) {
      await androidVolumeDownSub?.cancel();
    }
  }

  Future<void> initAsync() async {
    _hasAudioPermission = await Permission.microphone.isGranted;

    if (!_hasAudioPermission &&
        !userService.currentUser.requestedAudioPermission) {
      await updateUser((u) => u.requestedAudioPermission = true);
      await requestMicrophonePermission();
    }
  }

  Future<void> requestMicrophonePermission() async {
    final statuses = await [
      Permission.microphone,
    ].request();
    if (statuses[Permission.microphone]!.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      _hasAudioPermission = await Permission.microphone.isGranted;
      setState(() {
        // _hasAudioPermission
      });
    }
  }

  Future<void> updateScaleFactor(double newScale) async {
    if (mc.selectedCameraDetails.scaleFactor == newScale ||
        mc.cameraController == null) {
      return;
    }
    await mc.cameraController?.setZoomLevel(
      newScale.clamp(
        mc.selectedCameraDetails.minAvailableZoom,
        mc.selectedCameraDetails.maxAvailableZoom,
      ),
    );
    setState(() {
      mc.selectedCameraDetails.scaleFactor = newScale;
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
    if (mc.isSharePreviewIsShown || mc.isVideoRecording) return;

    setState(() {
      mc.isSharePreviewIsShown = true;
    });
    if (mc.selectedCameraDetails.isFlashOn) {
      if (isFront) {
        setState(() {
          _showSelfieFlash = true;
        });
      } else {
        await mc.cameraController?.setFlashMode(FlashMode.torch);
      }
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    await mc.cameraController?.pausePreview();
    if (!mounted) {
      return;
    }

    if (mc.cameraController?.value.flashMode != FlashMode.off) {
      await mc.cameraController?.setFlashMode(FlashMode.off);
    }

    if (!mounted) {
      return;
    }

    final image = await mc.screenshotController.capture(
      pixelRatio: MediaQuery.of(context).devicePixelRatio,
    );

    if (await pushMediaEditor(image, null)) {
      return;
    }
    setState(() {
      mc.isSharePreviewIsShown = false;
    });
  }

  Future<bool> pushMediaEditor(
    ScreenshotImageHelper? screenshotImage,
    File? videoFilePath, {
    bool sharedFromGallery = false,
    MediaType? mediaType,
  }) async {
    final type =
        mediaType ??
        ((videoFilePath != null) ? MediaType.video : MediaType.image);
    final mediaFileService = await initializeMediaUpload(
      type,
      userService.currentUser.defaultShowTime,
      isDraftMedia: true,
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

    await _deInitVolumeControl();
    if (!mounted) return true;

    final shouldReturn =
        await Navigator.push(
              context,
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (context, a1, a2) => ShareImageEditorView(
                  screenshotImage: screenshotImage,
                  sharedFromGallery: sharedFromGallery,
                  sendToGroup: widget.sendToGroup,
                  mediaFileService: mediaFileService,
                  mainCameraController: mc,
                  previewLink: mc.sharedLinkForPreview,
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return child;
                    },
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            )
            as bool?;
    if (mounted) {
      setState(() {
        mc.isSharePreviewIsShown = false;
        _showSelfieFlash = false;
      });
    }
    if (!mounted) return true;
    await initVolumeControl();
    // shouldReturn is null when the user used the back button
    if (shouldReturn != null && shouldReturn) {
      if (widget.sendToGroup == null) {
        HomeViewState.streamHomeViewPageIndex.add(0);
      } else if (mounted) {
        Navigator.pop(context);
      }
      return true;
    }
    await mc.selectCamera(
      mc.selectedCameraDetails.cameraId,
      false,
    );
    return false;
  }

  bool get isFront =>
      mc.cameraController?.description.lensDirection ==
      CameraLensDirection.front;

  Future<void> onPanUpdate(dynamic details) async {
    if (details == null) {
      return;
    }
    if (mc.cameraController == null ||
        !mc.cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      mc.selectedCameraDetails.scaleFactor =
          (_baseScaleFactor +
                  // ignore: avoid_dynamic_calls
                  (_basePanY - (details.localPosition.dy as double)) / 30)
              .clamp(1, mc.selectedCameraDetails.maxAvailableZoom);
    });
    await mc.cameraController!.setZoomLevel(
      mc.selectedCameraDetails.scaleFactor,
    );
  }

  Future<void> pickImageFromGallery() async {
    setState(() {
      _galleryLoadedImageIsShown = true;
      mc.isSharePreviewIsShown = true;
    });
    final picker = ImagePicker();
    final pickedFile = await picker.pickMedia();

    if (pickedFile != null) {
      final imageExtensions = [
        '.png',
        '.jpg',
        '.jpeg',
        '.gif',
        '.webp',
        '.heic',
        '.heif',
        '.avif',
      ];

      Log.info('Picket from gallery: ${pickedFile.path}');

      File? videoFilePath;
      ScreenshotImageHelper? image;
      MediaType? mediaType;

      final isImage = imageExtensions.any(
        (ext) => pickedFile.name.contains(ext),
      );
      if (isImage) {
        if (pickedFile.name.contains('.gif')) {
          mediaType = MediaType.gif;
        }
        image = ScreenshotImageHelper(
          imageBytesFuture: pickedFile.readAsBytes(),
        );
      } else {
        videoFilePath = File(pickedFile.path);
      }

      await pushMediaEditor(
        image,
        videoFilePath,
        sharedFromGallery: true,
        mediaType: mediaType,
      );
    }
    setState(() {
      _galleryLoadedImageIsShown = false;
      mc.isSharePreviewIsShown = false;
    });
  }

  Future<void> pressSideButtonLeft() async {
    if (!mc.isSelectingFaceFilters) {
      return pickImageFromGallery();
    }
    if (mc.currentFilterType.index == 1) {
      mc.setFilter(FaceFilterType.none);
      setState(() {
        mc.isSelectingFaceFilters = false;
      });
      return;
    }
    mc.setFilter(mc.currentFilterType.goLeft());
  }

  Future<void> pressSideButtonRight() async {
    if (!mc.isSelectingFaceFilters) {
      setState(() {
        mc.isSelectingFaceFilters = true;
      });
    }
    if (mc.currentFilterType.index == FaceFilterType.values.length - 1) {
      mc.setFilter(FaceFilterType.none);
      setState(() {
        mc.isSelectingFaceFilters = false;
      });
      return;
    }
    mc.setFilter(mc.currentFilterType.goRight());
  }

  Future<void> startVideoRecording() async {
    if (mc.cameraController != null &&
        mc.cameraController!.value.isRecordingVideo) {
      return;
    }
    setState(() {
      mc.isVideoRecording = true;
    });

    if (mc.selectedCameraDetails.isFlashOn) {
      await mc.cameraController?.setFlashMode(FlashMode.torch);
    }

    try {
      await mc.cameraController?.startVideoRecording();
      _videoRecordingTimer = Timer.periodic(const Duration(milliseconds: 15), (
        timer,
      ) {
        setState(() {
          _currentTime = clock.now();
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
        _videoRecordingStarted = clock.now();
        mc.isVideoRecording = true;
      });
    } on CameraException catch (e) {
      setState(() {
        mc.isVideoRecording = false;
      });
      _showCameraException(e);
      await mc.cameraController?.setFlashMode(FlashMode.off);
      return;
    }
  }

  Future<void> stopVideoRecording() async {
    if (_videoRecordingTimer != null) {
      _videoRecordingTimer?.cancel();
      _videoRecordingTimer = null;
    }

    await mc.cameraController?.setFlashMode(FlashMode.off);

    setState(() {
      _videoRecordingStarted = null;
      mc.isVideoRecording = false;
    });

    if (mc.cameraController == null ||
        !mc.cameraController!.value.isRecordingVideo) {
      return;
    }

    setState(() {
      mc.isSharePreviewIsShown = true;
    });

    try {
      final videoPath = await mc.cameraController?.stopVideoRecording();
      if (videoPath == null) return;
      await mc.cameraController?.pausePreview();
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
    if (mc.selectedCameraDetails.cameraId >= AppEnvironment.cameras.length ||
        mc.cameraController == null) {
      return Container();
    }
    return StreamBuilder(
      stream: userService.onUserUpdated,
      builder: (context, asyncSnapshot) {
        return MediaViewSizingHelper(
          requiredHeight: 0,
          additionalPadding: 59,
          bottomNavigation: Container(),
          child: GestureDetector(
            onPanStart: (details) async {
              setState(() {
                _basePanY = details.localPosition.dy;
                _baseScaleFactor = mc.selectedCameraDetails.scaleFactor;
              });
            },
            onLongPressMoveUpdate: onPanUpdate,
            onLongPressStart: (details) {
              setState(() {
                _basePanY = details.localPosition.dy;
                _baseScaleFactor = mc.selectedCameraDetails.scaleFactor;
              });
              // Get the position of the pointer
              final renderBox =
                  keyTriggerButton.currentContext!.findRenderObject()!
                      as RenderBox;
              final localPosition = renderBox.globalToLocal(
                details.globalPosition,
              );

              final containerRect = Rect.fromLTWH(
                0,
                0,
                renderBox.size.width,
                renderBox.size.height,
              );

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
                      height: 60,
                      width: 60,
                      child: ThreeRotatingDots(
                        size: 40,
                        color: context.color.primary,
                      ),
                    ),
                  ),
                if (!mc.isSharePreviewIsShown &&
                    widget.sendToGroup != null &&
                    !mc.isVideoRecording)
                  ShowTitleText(
                    title: widget.sendToGroup!.groupName,
                    desc: context.lang.cameraPreviewSendTo,
                  ),
                if (!mc.isSharePreviewIsShown &&
                    mc.sharedLinkForPreview != null &&
                    !mc.isVideoRecording)
                  ShowTitleText(
                    title: mc.sharedLinkForPreview?.host ?? '',
                    desc: 'Link',
                    isLink: true,
                  ),
                if (!mc.isSharePreviewIsShown &&
                    !mc.isVideoRecording &&
                    !widget.hideControllers)
                  CameraTopActions(
                    selectedCameraDetails: mc.selectedCameraDetails,
                    hasAudioPermission: _hasAudioPermission,
                    onSwitchCamera: () async {
                      await mc.selectCamera(
                        (mc.selectedCameraDetails.cameraId + 1) % 2,
                        false,
                      );
                    },
                    onToggleFlash: () async {
                      if (mc.selectedCameraDetails.isFlashOn) {
                        await mc.cameraController?.setFlashMode(FlashMode.off);
                        mc.selectedCameraDetails.isFlashOn = false;
                      } else {
                        await mc.cameraController?.setFlashMode(
                          FlashMode.always,
                        );
                        mc.selectedCameraDetails.isFlashOn = true;
                      }
                      setState(() {
                        // mc.selectedCameraDetails.isFlashOn
                      });
                    },
                    onRequestMicrophone: requestMicrophonePermission,
                  ),
                if (!mc.isSharePreviewIsShown && !widget.hideControllers)
                  CameraBottomControls(
                    mainController: mc,
                    isVideoRecording: mc.isVideoRecording,
                    isFront: isFront,
                    keyTriggerButton: keyTriggerButton,
                    onTakePicture: takePicture,
                    onPressSideButtonLeft: pressSideButtonLeft,
                    onPressSideButtonRight: pressSideButtonRight,
                    updateScaleFactor: updateScaleFactor,
                  ),
                VideoRecordingTimer(
                  videoRecordingStarted: _videoRecordingStarted,
                  maxVideoRecordingTime: maxVideoRecordingTime,
                ),
                if (!mc.isSharePreviewIsShown && widget.sendToGroup != null ||
                    widget.hideControllers)
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
                if (_showSelfieFlash) const CameraSelfieFlash(),
                CameraScannedOverlay(mainController: mc),
              ],
            ),
          ),
        );
      },
    );
  }
}
