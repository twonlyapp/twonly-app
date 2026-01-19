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
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/qr.dart';
import 'package:twonly/src/utils/screenshot.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera/camera_preview_components/face_filters.dart';
import 'package:twonly/src/views/camera/camera_preview_components/main_camera_controller.dart';
import 'package:twonly/src/views/camera/camera_preview_components/permissions_view.dart';
import 'package:twonly/src/views/camera/camera_preview_components/send_to.dart';
import 'package:twonly/src/views/camera/camera_preview_components/video_recording_time.dart';
import 'package:twonly/src/views/camera/camera_preview_components/zoom_selector.dart';
import 'package:twonly/src/views/camera/share_image_editor.view.dart';
import 'package:twonly/src/views/camera/share_image_editor/action_button.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/loader.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';
import 'package:twonly/src/views/home.view.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
  bool _sharePreviewIsShown = false;
  bool _galleryLoadedImageIsShown = false;
  bool _showSelfieFlash = false;
  double _basePanY = 0;
  double _baseScaleFactor = 0;
  bool _isVideoRecording = false;
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
        deInitVolumeControl();
      }
    }
  }

  @override
  void dispose() {
    _videoRecordingTimer?.cancel();
    deInitVolumeControl();
    super.dispose();
  }

  Future<void> initVolumeControl() async {
    if (Platform.isIOS) {
      await FlutterVolumeController.updateShowSystemUI(false);
      double? startedVolume;

      FlutterVolumeController.addListener(
        (volume) async {
          if (!widget.isVisible) {
            await deInitVolumeControl();
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
        androidVolumeDownSub =
            FlutterAndroidVolumeKeydown.stream.listen((event) {
          if (widget.isVisible) {
            takePicture();
          } else {
            deInitVolumeControl();
            return;
          }
        });
      }
    }
  }

  Future<void> deInitVolumeControl() async {
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
    if (_sharePreviewIsShown || _isVideoRecording) return;

    setState(() {
      _sharePreviewIsShown = true;
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

    final image = await mc.screenshotController
        .capture(pixelRatio: MediaQuery.of(context).devicePixelRatio);

    if (await pushMediaEditor(image, null)) {
      return;
    }
    setState(() {
      _sharePreviewIsShown = false;
    });
  }

  Future<bool> pushMediaEditor(
    ScreenshotImage? imageBytes,
    File? videoFilePath, {
    bool sharedFromGallery = false,
    MediaType? mediaType,
  }) async {
    final type = mediaType ??
        ((videoFilePath != null) ? MediaType.video : MediaType.image);
    final mediaFileService = await initializeMediaUpload(
      type,
      gUser.defaultShowTime,
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

    await deInitVolumeControl();
    if (!mounted) return true;

    final shouldReturn = await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, a1, a2) => ShareImageEditorView(
          imageBytesFuture: imageBytes,
          sharedFromGallery: sharedFromGallery,
          sendToGroup: widget.sendToGroup,
          mediaFileService: mediaFileService,
          mainCameraController: mc,
          previewLink: mc.sharedLinkForPreview,
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
    await initVolumeControl();
    // shouldReturn is null when the user used the back button
    if (shouldReturn != null && shouldReturn) {
      if (widget.sendToGroup == null) {
        globalUpdateOfHomeViewPageIndex(0);
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

    mc.selectedCameraDetails.scaleFactor = (_baseScaleFactor +
            // ignore: avoid_dynamic_calls
            (_basePanY - (details.localPosition.dy as double)) / 30)
        .clamp(1, mc.selectedCameraDetails.maxAvailableZoom);

    await mc.cameraController!
        .setZoomLevel(mc.selectedCameraDetails.scaleFactor);
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
      ScreenshotImage? image;
      MediaType? mediaType;

      final isImage =
          imageExtensions.any((ext) => pickedFile.name.contains(ext));
      if (isImage) {
        if (pickedFile.name.contains('.gif')) {
          mediaType = MediaType.gif;
        }
        image = ScreenshotImage(imageBytesFuture: pickedFile.readAsBytes());
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
      _sharePreviewIsShown = false;
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
      _isVideoRecording = true;
    });

    try {
      await mc.cameraController?.startVideoRecording();
      _videoRecordingTimer =
          Timer.periodic(const Duration(milliseconds: 15), (timer) {
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

    if (mc.cameraController == null ||
        !mc.cameraController!.value.isRecordingVideo) {
      return;
    }

    setState(() {
      _sharePreviewIsShown = true;
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
    if (mc.selectedCameraDetails.cameraId >= gCameras.length ||
        mc.cameraController == null) {
      return Container();
    }
    return MediaViewSizing(
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
                  height: 60,
                  width: 60,
                  child: ThreeRotatingDots(
                    size: 40,
                    color: context.color.primary,
                  ),
                ),
              ),
            if (!_sharePreviewIsShown &&
                widget.sendToGroup != null &&
                !_isVideoRecording)
              ShowTitleText(
                title: widget.sendToGroup!.groupName,
                desc: context.lang.cameraPreviewSendTo,
              ),
            if (!_sharePreviewIsShown &&
                mc.sharedLinkForPreview != null &&
                !_isVideoRecording)
              ShowTitleText(
                title: mc.sharedLinkForPreview?.host ?? '',
                desc: 'Link',
                isLink: true,
              ),
            if (!_sharePreviewIsShown &&
                !_isVideoRecording &&
                !widget.hideControllers)
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
                            await mc.selectCamera(
                              (mc.selectedCameraDetails.cameraId + 1) % 2,
                              false,
                            );
                          },
                        ),
                        ActionButton(
                          mc.selectedCameraDetails.isFlashOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          tooltipText: context.lang.toggleFlashLight,
                          color: mc.selectedCameraDetails.isFlashOn
                              ? Colors.white
                              : Colors.white.withAlpha(160),
                          onPressed: () async {
                            if (mc.selectedCameraDetails.isFlashOn) {
                              await mc.cameraController
                                  ?.setFlashMode(FlashMode.off);
                              mc.selectedCameraDetails.isFlashOn = false;
                            } else {
                              await mc.cameraController
                                  ?.setFlashMode(FlashMode.always);
                              mc.selectedCameraDetails.isFlashOn = true;
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
            if (!_sharePreviewIsShown && !widget.hideControllers)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    children: [
                      if (mc.cameraController!.value.isInitialized &&
                          mc.selectedCameraDetails.isZoomAble &&
                          !_isVideoRecording)
                        SizedBox(
                          width: 120,
                          child: CameraZoomButtons(
                            key: mc.zoomButtonKey,
                            scaleFactor: mc.selectedCameraDetails.scaleFactor,
                            updateScaleFactor: updateScaleFactor,
                            selectCamera: mc.selectCamera,
                            selectedCameraDetails: mc.selectedCameraDetails,
                            controller: mc.cameraController!,
                          ),
                        ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_isVideoRecording)
                            GestureDetector(
                              onTap: pressSideButtonLeft,
                              child: Align(
                                child: Container(
                                  height: 50,
                                  width: 80,
                                  padding: const EdgeInsets.all(2),
                                  child: Center(
                                    child: FaIcon(
                                      mc.isSelectingFaceFilters
                                          ? mc.currentFilterType.index == 1
                                              ? FontAwesomeIcons.xmark
                                              : FontAwesomeIcons.arrowLeft
                                          : FontAwesomeIcons.photoFilm,
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
                                child: mc.currentFilterType.preview,
                              ),
                            ),
                          ),
                          if (!_isVideoRecording)
                            if (isFront)
                              GestureDetector(
                                onTap: pressSideButtonRight,
                                child: Align(
                                  child: Container(
                                    height: 50,
                                    width: 80,
                                    padding: const EdgeInsets.all(2),
                                    child: Center(
                                      child: FaIcon(
                                        mc.isSelectingFaceFilters
                                            ? mc.currentFilterType.index ==
                                                    FaceFilterType
                                                            .values.length -
                                                        1
                                                ? FontAwesomeIcons.xmark
                                                : FontAwesomeIcons.arrowRight
                                            : FontAwesomeIcons
                                                .faceGrinTongueSquint,
                                        color: Colors.white,
                                        size: 25,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(width: 80),
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
            if (!_sharePreviewIsShown && widget.sendToGroup != null ||
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
            if (_showSelfieFlash)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    color: Colors.white,
                  ),
                ),
              ),
            Positioned(
              right: 8,
              top: 170,
              child: SizedBox(
                height: 200,
                width: 150,
                child: ListView(
                  children: [
                    ...widget.mainCameraController.scannedNewProfiles.values
                        .map(
                      (c) {
                        if (c.isLoading) return Container();
                        return GestureDetector(
                          onTap: () async {
                            c.isLoading = true;
                            widget.mainCameraController.setState();
                            await addNewContactFromPublicProfile(c.profile);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: context.color.surfaceContainer,
                            ),
                            child: Row(
                              children: [
                                Text(c.profile.username),
                                Expanded(child: Container()),
                                if (c.isLoading)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  ColoredBox(
                                    color: Colors.transparent,
                                    child: FaIcon(
                                      FontAwesomeIcons.userPlus,
                                      color: isDarkMode(context)
                                          ? Colors.white
                                          : Colors.black,
                                      size: 17,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    ...widget.mainCameraController.contactsVerified.values.map(
                      (c) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: context.color.surfaceContainer,
                          ),
                          child: Row(
                            children: [
                              AvatarIcon(
                                contactId: c.contact.userId,
                                fontSize: 14,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                getContactDisplayName(
                                  c.contact,
                                  maxLength: 13,
                                ),
                              ),
                              Expanded(
                                child: Container(),
                              ),
                              ColoredBox(
                                color: Colors.transparent,
                                child: SizedBox(
                                  width: 30,
                                  child: Lottie.asset(
                                    c.verificationOk
                                        ? 'assets/animations/success.json'
                                        : 'assets/animations/failed.json',
                                    repeat: false,
                                    onLoaded: (p0) {
                                      Future.delayed(const Duration(seconds: 4),
                                          () {
                                        widget.mainCameraController.setState();
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (widget.mainCameraController.scannedUrl != null)
                      GestureDetector(
                        onTap: () {
                          launchUrlString(
                            widget.mainCameraController.scannedUrl!,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: context.color.surfaceContainer,
                          ),
                          child: Row(
                            children: [
                              Text(
                                substringBy(
                                  widget.mainCameraController.scannedUrl!,
                                  25,
                                ),
                                style: const TextStyle(fontSize: 8),
                              ),
                              Expanded(
                                child: Container(),
                              ),
                              Expanded(child: Container()),
                              ColoredBox(
                                color: Colors.transparent,
                                child: FaIcon(
                                  FontAwesomeIcons.shareFromSquare,
                                  color: isDarkMode(context)
                                      ? Colors.white
                                      : Colors.black,
                                  size: 17,
                                ),
                              ),
                            ],
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
    );
  }
}
