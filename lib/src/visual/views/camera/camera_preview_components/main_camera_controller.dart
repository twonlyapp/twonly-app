import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/qr.pb.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart'
    show PasswordlessRecoveryService;
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/qr.utils.dart';
import 'package:twonly/src/visual/components/add_contact_dialog.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/components/verification_success_dialog.comp.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview_controller_view.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/face_filters.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/painters/barcode_detector_painter.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/painters/face_filters/beard_filter_painter.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/painters/face_filters/dog_filter_painter.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/painters/face_filters/face_filter_painter.dart';

class PreviewLink {
  const PreviewLink({
    required this.url,
    required this.shouldGeneratePreview,
  });

  final Uri url;
  final bool shouldGeneratePreview;
}

class ScannedVerifiedContact {
  ScannedVerifiedContact({required this.contact, required this.verificationOk});
  Contact contact;
  bool verificationOk;
}

class ScannedNewProfile {
  ScannedNewProfile({required this.profile, this.isLoading = false});
  PublicProfile profile;
  bool isLoading;
}

class MainCameraController {
  void Function()? setState;
  CameraController? cameraController;
  ScreenshotController screenshotController = ScreenshotController();
  SelectedCameraDetails selectedCameraDetails = SelectedCameraDetails();
  bool initCameraStarted = false;
  Map<int, ScannedVerifiedContact> contactsVerified = {};
  Map<int, ScannedNewProfile> scannedNewProfiles = {};
  final Set<String> _handledProfileLinks = {};
  String? scannedUrl;
  GlobalKey zoomButtonKey = GlobalKey();
  GlobalKey cameraPreviewKey = GlobalKey();

  bool isSelectingFaceFilters = false;
  bool isSharePreviewIsShown = false;
  bool isVideoRecording = false;
  DateTime? timeSharedLinkWasSetWithQr;

  PreviewLink? sharedLinkForPreview;

  void setSharedLinkForPreview(Uri? url, {bool generatePreview = true}) {
    sharedLinkForPreview = url == null
        ? null
        : PreviewLink(url: url, shouldGeneratePreview: generatePreview);
    setState?.call();
  }

  void onImageSend() {
    scannedUrl = '';
    setState?.call();
  }

  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );
  bool _isBusy = false;
  bool _isBusyFaces = false;
  CustomPaint? qrCodePain;
  CustomPaint? facePaint;
  Offset? focusPointOffset;

  FaceFilterType _currentFilterType = FaceFilterType.none;
  FaceFilterType get currentFilterType => _currentFilterType;

  Future<void>? _initializeFuture;
  Future<void>? _pendingDisposal;
  int _cameraSessionId = 0;

  Future<void> closeCamera() async {
    _cameraSessionId++;
    contactsVerified = {};
    scannedNewProfiles = {};
    scannedUrl = null;
    final cameraControllerTemp = cameraController;
    cameraController = null;
    final initFutureTemp = _initializeFuture;
    _initializeFuture = null;
    // prevents: CameraException(Disposed CameraController, buildPreview() was called on a disposed CameraController.)
    _pendingDisposal = Future.delayed(
      const Duration(milliseconds: 100),
      () async {
        try {
          if (initFutureTemp != null) {
            await initFutureTemp;
          }
          // ignore: empty_catches
        } catch (e) {}
        try {
          await cameraControllerTemp?.stopImageStream();
          // ignore: empty_catches
        } catch (e) {}
        await cameraControllerTemp?.dispose();
      },
    );
    initCameraStarted = false;
    selectedCameraDetails = SelectedCameraDetails();
    setState?.call();
  }

  Future<void> selectCamera(int sCameraId, bool init) async {
    if (initCameraStarted) return;
    initCameraStarted = true;
    final sessionId = ++_cameraSessionId;

    // Start checking microphone permission concurrently
    final micPermissionFuture = Permission.microphone.isGranted;

    try {
      await _pendingDisposal;
      if (sessionId != _cameraSessionId) return;

      if (AppEnvironment.cameras.isEmpty) {
        AppEnvironment.cameras = await availableCameras();
        if (sessionId != _cameraSessionId) return;
      }
    } catch (e) {
      Log.error('Error querying available cameras: $e');
      initCameraStarted = false;
      return;
    }

    var cameraId = sCameraId;
    if (cameraId >= AppEnvironment.cameras.length) {
      Log.warn(
        'Trying to select a non existing camera $cameraId >= ${AppEnvironment.cameras.length}',
      );
      initCameraStarted = false;
      return;
    }

    if (init) {
      for (; cameraId < AppEnvironment.cameras.length; cameraId++) {
        if (AppEnvironment.cameras[cameraId].lensDirection ==
            CameraLensDirection.back) {
          break;
        }
      }
      if (cameraId >= AppEnvironment.cameras.length) {
        cameraId = sCameraId;
      }
    }

    selectedCameraDetails.isZoomAble = false;

    final currentController = cameraController;
    if (currentController == null || !currentController.value.isInitialized) {
      final controllerToDispose = cameraController;
      cameraController = null;
      if (controllerToDispose != null) {
        unawaited(controllerToDispose.dispose());
      }

      final hasMic = await micPermissionFuture;
      if (sessionId != _cameraSessionId) return;

      final controller = CameraController(
        AppEnvironment.cameras[cameraId],
        ResolutionPreset.high,
        enableAudio: hasMic,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      var assignedToGlobal = false;
      try {
        _initializeFuture = controller.initialize();
        await _initializeFuture;
        if (sessionId != _cameraSessionId) {
          unawaited(controller.dispose());
          return;
        }

        if (!controller.value.isInitialized) {
          throw CameraException(
            'Uninitialized CameraController',
            'CameraController was not initialized after initialize() completed.',
          );
        }

        await controller.startImageStream(_processCameraImage);
        if (sessionId != _cameraSessionId) {
          unawaited(controller.dispose());
          return;
        }

        await controller.setZoomLevel(selectedCameraDetails.scaleFactor);
        if (sessionId != _cameraSessionId) {
          unawaited(controller.dispose());
          return;
        }

        if (userService.currentUser.videoStabilizationEnabled && !kDebugMode) {
          await controller.setVideoStabilizationMode(
            VideoStabilizationMode.level1,
          );
          if (sessionId != _cameraSessionId) {
            unawaited(controller.dispose());
            return;
          }
        }

        cameraController = controller;
        assignedToGlobal = true;
      } catch (e) {
        if (e is CameraException) {
          Log.warn('Camera initialization failed (CameraException): $e');
        } else {
          Log.error('Error initializing camera: $e');
        }
        if (!assignedToGlobal) {
          unawaited(controller.dispose());
        } else {
          if (cameraController == controller) {
            cameraController = null;
          }
          unawaited(controller.dispose());
        }
        initCameraStarted = false;
        return;
      }
    } else {
      try {
        if (!isVideoRecording) {
          try {
            await currentController.stopImageStream();
          } catch (e) {
            Log.warn('Could not stop image stream: $e');
          }
        }
        if (sessionId != _cameraSessionId) return;

        selectedCameraDetails.scaleFactor = 1;

        await currentController.setZoomLevel(1);
        if (sessionId != _cameraSessionId) return;

        await currentController.setDescription(
          AppEnvironment.cameras[cameraId],
        );
        if (sessionId != _cameraSessionId) return;

        if (!isVideoRecording) {
          await currentController.startImageStream(_processCameraImage);
        }
      } catch (e) {
        if (e is CameraException) {
          Log.warn('Camera description switch failed (CameraException): $e');
        } else {
          Log.error('Error switching camera description: $e');
        }
        initCameraStarted = false;
        return;
      }
    }

    if (sessionId != _cameraSessionId) return;
    final controller = cameraController;
    if (controller == null) {
      initCameraStarted = false;
      return;
    }

    try {
      await controller.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );
      if (sessionId != _cameraSessionId) return;

      await controller.setFlashMode(
        selectedCameraDetails.isFlashOn ? FlashMode.always : FlashMode.off,
      );
      if (sessionId != _cameraSessionId) return;

      selectedCameraDetails.maxAvailableZoom = await controller
          .getMaxZoomLevel();
      if (sessionId != _cameraSessionId) return;

      selectedCameraDetails.minAvailableZoom = await controller
          .getMinZoomLevel();
      if (sessionId != _cameraSessionId) return;

      selectedCameraDetails
        ..isZoomAble =
            selectedCameraDetails.maxAvailableZoom !=
            selectedCameraDetails.minAvailableZoom
        ..cameraLoaded = true
        ..cameraId = cameraId;

      facePaint = null;
      qrCodePain = null;
      isSelectingFaceFilters = false;
      setFilter(FaceFilterType.none);
      zoomButtonKey = GlobalKey();
      initCameraStarted = false;
      setState?.call();
    } catch (e) {
      if (e is CameraException) {
        Log.warn('Camera post-initialization failed (CameraException): $e');
      } else {
        Log.error('Error post-initializing camera: $e');
      }
      if (cameraController == controller) {
        cameraController = null;
      }
      unawaited(controller.dispose());
      initCameraStarted = false;
      return;
    }
  }

  Future<void> onDoubleTap() async {
    await selectCamera((selectedCameraDetails.cameraId + 1) % 2, false);
  }

  Future<void> onTapDown(TapDownDetails details) async {
    final box =
        cameraPreviewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPosition = box.globalToLocal(details.globalPosition);

    focusPointOffset = Offset(localPosition.dx, localPosition.dy);

    final dx = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    final dy = (localPosition.dy / box.size.height).clamp(0.0, 1.0);

    setState?.call();

    await HapticFeedback.lightImpact();
    try {
      await cameraController?.setFocusPoint(Offset(dx, dy));
      await cameraController?.setFocusMode(FocusMode.auto);
    } catch (e) {
      if (e is CameraException &&
          (e.code == 'setFocusPointFailed' || e.code == 'setFocusModeFailed')) {
        Log.info('Focus point or mode not supported on this device');
      } else {
        Log.warn(e);
      }
    }

    // display the focus point at least 500ms
    await Future.delayed(const Duration(milliseconds: 500));

    focusPointOffset = null;
    setState?.call();
  }

  void setFilter(FaceFilterType type) {
    _currentFilterType = type;
    if (_currentFilterType == FaceFilterType.none) {
      faceFilterPainter = null;
      facePaint = null;
      _isBusyFaces = false;
    }
    setState?.call();
  }

  FaceFilterPainter? faceFilterPainter;

  final Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  void _processCameraImage(CameraImage image) {
    if (isVideoRecording || isSharePreviewIsShown) {
      return;
    }
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    // check if front camera is selected
    if (cameraController?.description.lensDirection ==
        CameraLensDirection.front) {
      if (_currentFilterType != FaceFilterType.none) {
        _processFaces(inputImage);
      }
    } else {
      _processBarcode(inputImage);
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final controller = cameraController;
    if (controller == null) return null;
    final camera = controller.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // get image format
    var format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (Platform.isAndroid && format == InputImageFormat.yuv420) {
      // https://developer.android.com/reference/kotlin/androidx/camera/core/ImageAnalysis#OUTPUT_IMAGE_FORMAT_NV21()
      format = InputImageFormat.nv21;
    }
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  Future<void> _processBarcode(InputImage inputImage) async {
    if (_isBusy) return;
    _isBusy = true;
    final barcodes = await _barcodeScanner.processImage(inputImage);
    final controller = cameraController;
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null &&
        controller != null) {
      final painter = BarcodeDetectorPainter(
        barcodes,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        controller.description.lensDirection,
      );
      qrCodePain = CustomPaint(painter: painter);

      if (barcodes.isEmpty && timeSharedLinkWasSetWithQr != null) {
        if (timeSharedLinkWasSetWithQr!.isAfter(
          DateTime.now().subtract(const Duration(seconds: 2)),
        )) {
          setSharedLinkForPreview(null);
        }
      }

      for (final barcode in barcodes) {
        if (barcode.displayValue == null) continue;
        final link = barcode.displayValue!;

        if (link.startsWith(PasswordlessRecoveryService.linkPrefix)) {
          await PasswordlessRecoveryService.handleRecoveryLink(link);
          continue;
        }

        if (link.startsWith(QrCodeUtils.linkPrefix)) {
          if (_handledProfileLinks.contains(link)) continue;
          _handledProfileLinks.add(link);

          final res = await QrCodeUtils.handleQrCodeLink(link);
          if (res == null) continue;
          final (profile, contact, verificationOk) = res;

          if (contact?.blocked ?? false) {
            await twonlyDB.contactsDao.updateContact(
              contact!.userId,
              const ContactsCompanion(blocked: Value(false)),
            );
          }

          if (contact == null || contact.deletedByUser) {
            final context = cameraPreviewKey.currentContext;
            if (context != null && context.mounted) {
              unawaited(HapticFeedback.heavyImpact());
              final shouldRequest = await AddContactDialog.show(
                context,
                profile.username,
              );
              if (shouldRequest == true && context.mounted) {
                showSnackbar(
                  context,
                  context.lang.requestedUserToastText(profile.username),
                  level: SnackbarLevel.success,
                );
                await addNewContactFromPublicProfile(profile);
              }
            }
            continue;
          }

          if (contactsVerified[contact.userId] == null) {
            contactsVerified[contact.userId] = ScannedVerifiedContact(
              contact: contact,
              verificationOk: verificationOk,
            );

            unawaited(HapticFeedback.heavyImpact());
            final context = cameraPreviewKey.currentContext;
            if (verificationOk && context != null && context.mounted) {
              await VerificationSuccessDialog.show(context, contact);
            }
          }
          continue;
        }

        if (link.startsWith('http://') || link.startsWith('https://')) {
          scannedUrl = link;
          if (sharedLinkForPreview == null) {
            timeSharedLinkWasSetWithQr = clock.now();
            setSharedLinkForPreview(
              Uri.parse(scannedUrl!),
              generatePreview: false,
            );
          }
        }
      }
    }
    _isBusy = false;
    setState?.call();
  }

  Future<void> _processFaces(InputImage inputImage) async {
    if (_isBusyFaces) return;
    _isBusyFaces = true;
    final faces = await _faceDetector.processImage(inputImage);
    final controller = cameraController;
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null &&
        controller != null) {
      if (faces.isNotEmpty) {
        CustomPainter? painter;
        switch (_currentFilterType) {
          case FaceFilterType.dogBrown:
            painter = DogFilterPainter(
              faces,
              inputImage.metadata!.size,
              inputImage.metadata!.rotation,
              controller.description.lensDirection,
            );
          case FaceFilterType.beardUpperLipGreen:
            painter = BeardFilterPainter(
              _currentFilterType,
              faces,
              inputImage.metadata!.size,
              inputImage.metadata!.rotation,
              controller.description.lensDirection,
            );
          case FaceFilterType.none:
            break;
        }

        if (painter != null) {
          facePaint = CustomPaint(painter: painter);
          // Also set the correct FaceFilterPainter reference if needed for other logic,
          // though currently facePaint is what's used for display.
          if (painter is FaceFilterPainter) {
            faceFilterPainter = painter;
          }
        } else {
          facePaint = null;
          faceFilterPainter = null;
        }
      } else {
        facePaint = null;
      }
    }
    _isBusyFaces = false;
    setState?.call();
  }
}
