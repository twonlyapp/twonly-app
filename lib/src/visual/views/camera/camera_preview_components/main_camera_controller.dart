import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/protobuf/client/generated/qr.pb.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart'
    show PasswordlessRecoveryService;
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/qr.utils.dart';
import 'package:twonly/src/visual/components/add_contact_dialog.comp.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/components/verification_failure_dialog.comp.dart';
import 'package:twonly/src/visual/components/verification_success_dialog.comp.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview_controller_view.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/painters/barcode_detector_painter.dart';

// Ordinary photos retain the rear camera's 1080p preview. Selfie previews
// use 720p.
ResolutionPreset cameraPreviewResolution(CameraLensDirection direction) =>
    direction == CameraLensDirection.front
    ? ResolutionPreset.high
    : ResolutionPreset.veryHigh;

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
  void Function(Contact contact)? onVerificationSuccessDismissed;
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

  bool _isSharePreviewIsShown = false;
  bool get isSharePreviewIsShown => _isSharePreviewIsShown;
  set isSharePreviewIsShown(bool value) {
    if (_isSharePreviewIsShown == value) return;
    _isSharePreviewIsShown = value;
    setState?.call();
  }

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
    scannedUrl = null;
    setState?.call();
  }

  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isBusy = false;
  CustomPaint? qrCodePain;
  Color? scanHighlightColor;
  Offset? focusPointOffset;

  // CameraX shares one native camera across controllers. Keep initialization,
  // lens changes and disposal ordered, including across camera views.
  static Future<void> _cameraOperations = Future<void>.value();

  static Future<void> _runCameraOperation(Future<void> Function() operation) {
    final result = _cameraOperations.then((_) => operation());
    // A failed operation must not prevent subsequent cleanup or reopening.
    _cameraOperations = result.then<void>((_) {}, onError: (Object error) {});
    return result;
  }

  int _cameraSessionId = 0;
  DateTime? _lastBarcodeFrame;

  Future<void> closeCamera() async {
    _cameraSessionId++;
    contactsVerified = {};
    scannedNewProfiles = {};
    scannedUrl = null;
    final cameraControllerTemp = cameraController;
    cameraController = null;
    final disposal = _runCameraOperation(() async {
      // Let the preview leave the widget tree before disposing its controller.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (cameraControllerTemp == null) return;
      try {
        if (cameraControllerTemp.value.isStreamingImages) {
          await cameraControllerTemp.stopImageStream();
        }
      } catch (e) {
        Log.warn('Could not stop image stream while closing camera: $e');
      } finally {
        await cameraControllerTemp.dispose();
      }
    });
    initCameraStarted = false;
    selectedCameraDetails = SelectedCameraDetails();
    setState?.call();
    await disposal;
  }

  Future<void> selectCamera(int sCameraId, bool init) async {
    if (initCameraStarted) return;
    initCameraStarted = true;
    final sessionId = ++_cameraSessionId;

    await _runCameraOperation(() async {
      if (sessionId != _cameraSessionId) return;
      try {
        await _selectCamera(sCameraId, init, sessionId);
      } finally {
        // An old selection must not reset a newer selection's loading state.
        if (sessionId == _cameraSessionId) {
          initCameraStarted = false;
          setState?.call();
        }
      }
    });
  }

  Future<void> _selectCamera(int sCameraId, bool init, int sessionId) async {
    // Start checking microphone permission concurrently
    final micPermissionFuture = Permission.microphone.isGranted;

    try {
      if (AppEnvironment.cameras.isEmpty) {
        AppEnvironment.cameras = await availableCameras();
        if (sessionId != _cameraSessionId) return;
      }
    } catch (e) {
      Log.error('Error querying available cameras: $e');
      setState?.call();
      return;
    }

    var cameraId = sCameraId;
    if (cameraId >= AppEnvironment.cameras.length) {
      Log.warn(
        'Trying to select a non existing camera $cameraId >= ${AppEnvironment.cameras.length}',
      );
      setState?.call();
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
    _lastBarcodeFrame = null;
    final currentController = cameraController;
    // Preserve an active recording's preset when switching lenses. Recreating
    // its controller just to lower the selfie preview would end the video.
    final resolution = isVideoRecording && currentController != null
        ? currentController.resolutionPreset
        : cameraPreviewResolution(
            AppEnvironment.cameras[cameraId].lensDirection,
          );
    if (currentController == null ||
        !currentController.value.isInitialized ||
        currentController.resolutionPreset != resolution) {
      final controllerToDispose = cameraController;
      cameraController = null;
      setState?.call();
      if (controllerToDispose != null) {
        await controllerToDispose.dispose();
        if (sessionId != _cameraSessionId) return;
      }

      final hasMic = await micPermissionFuture;
      if (sessionId != _cameraSessionId) return;

      var controller = CameraController(
        AppEnvironment.cameras[cameraId],
        resolution,
        enableAudio: hasMic,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      var assignedToGlobal = false;
      try {
        try {
          await controller.initialize();
        } on CameraException catch (e) {
          // If specific image format is unsupported on this hardware, fallback to default format
          Log.warn(
            'Initial camera format initialization failed ($e), trying fallback format...',
          );
          await controller.dispose();
          controller = CameraController(
            AppEnvironment.cameras[cameraId],
            resolution,
            enableAudio: hasMic,
          );
          await controller.initialize();
        }

        if (sessionId != _cameraSessionId) {
          await controller.dispose();
          return;
        }

        if (!controller.value.isInitialized) {
          throw CameraException(
            'Uninitialized CameraController',
            'CameraController was not initialized after initialize() completed.',
          );
        }

        if (controller.description.lensDirection != CameraLensDirection.front) {
          await controller.startImageStream(_processCameraImage);
        }
        if (sessionId != _cameraSessionId) {
          await controller.dispose();
          return;
        }

        await controller.setZoomLevel(selectedCameraDetails.scaleFactor);
        if (sessionId != _cameraSessionId) {
          await controller.dispose();
          return;
        }

        if (userService.currentUser.videoStabilizationEnabled && !kDebugMode) {
          // Stabilization buys its steadiness with a margin of sensor pixels to
          // warp against, so it always narrows the field of view. On Android
          // level2 maps to Camera2's PREVIEW_STABILIZATION, which narrows the
          // preview by the same amount as the recording, so the viewfinder
          // shows what gets sent; level1 is plain VIDEO_STABILIZATION_MODE_ON,
          // which crops the recording alone and leaves the preview wider than
          // the result. On iOS level2 is AVFoundation's `.cinematic`, which
          // crops harder than the `.standard` level1 maps to without matching
          // the preview any better, so iOS stays where it was. Both fall back
          // down the levels, and finally to off, on a camera without the mode.
          await controller.setVideoStabilizationMode(
            Platform.isAndroid
                ? VideoStabilizationMode.level2
                : VideoStabilizationMode.level1,
          );
          if (sessionId != _cameraSessionId) {
            await controller.dispose();
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
          await controller.dispose();
        } else {
          if (cameraController == controller) {
            cameraController = null;
          }
          await controller.dispose();
        }
        setState?.call();
        return;
      }
    } else {
      try {
        if (!isVideoRecording && currentController.value.isStreamingImages) {
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

        if (!isVideoRecording &&
            currentController.description.lensDirection !=
                CameraLensDirection.front) {
          await currentController.startImageStream(_processCameraImage);
        }
      } catch (e) {
        if (e is CameraException) {
          Log.warn('Camera description switch failed (CameraException): $e');
        } else {
          Log.error('Error switching camera description: $e');
        }
        return;
      }
    }

    if (sessionId != _cameraSessionId) return;
    final controller = cameraController;
    if (controller == null) {
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

      qrCodePain = null;
      zoomButtonKey = GlobalKey();
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
      await controller.dispose();
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
    if (cameraController?.description.lensDirection ==
            CameraLensDirection.front ||
        _isBusy) {
      return;
    }
    final now = clock.now();
    if (_lastBarcodeFrame != null &&
        now.difference(_lastBarcodeFrame!) <
            const Duration(milliseconds: 150)) {
      return;
    }
    _lastBarcodeFrame = now;
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage != null) unawaited(_processBarcode(inputImage));
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
    try {
      final barcodes = await _barcodeScanner.processImage(inputImage);
      final controller = cameraController;
      if (inputImage.metadata?.size != null &&
          inputImage.metadata?.rotation != null &&
          controller != null &&
          scanHighlightColor != null) {
        final painter = BarcodeDetectorPainter(
          barcodes,
          inputImage.metadata!.size,
          inputImage.metadata!.rotation,
          controller.description.lensDirection,
          scanHighlightColor!,
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

            final result = await QrCodeUtils.handleQrCodeLink(link);
            final profile = result.profile;
            final contact = result.contact;

            if (result.status == QrCodeLinkStatus.contactRequested) {
              final context = cameraPreviewKey.currentContext;
              if (context != null && context.mounted) {
                unawaited(HapticFeedback.heavyImpact());
                showSnackbar(
                  context,
                  context.lang.requestedUserToastText(profile!.username),
                  level: SnackbarLevel.success,
                );
              }
              continue;
            }

            if (contact?.blocked ?? false) {
              await rust_contacts.updateContact(
                id: contact!.userId,
                patch: const ContactPatch(blocked: false),
                transaction: currentDatabaseSession(),
              );
            }

            if (result.status == QrCodeLinkStatus.newContact) {
              final context = cameraPreviewKey.currentContext;
              if (profile != null && context != null && context.mounted) {
                unawaited(HapticFeedback.heavyImpact());
                final shouldRequest = await AddContactDialog.show(
                  context,
                  profile.username,
                );
                if (shouldRequest == true && context.mounted) {
                  final success = await addNewContactFromPublicProfile(profile);
                  if (context.mounted) {
                    if (success) {
                      showSnackbar(
                        context,
                        context.lang.requestedUserToastText(profile.username),
                        level: SnackbarLevel.success,
                      );
                    } else {
                      await showAlertDialog(
                        context,
                        context.lang.addFriendTitle,
                        context.lang.additionalUserAddError(profile.username),
                        customCancel: '',
                      );
                    }
                  }
                }
              }
              continue;
            }

            if (result.status != QrCodeLinkStatus.verified) {
              final context = cameraPreviewKey.currentContext;
              if (context != null && context.mounted) {
                unawaited(HapticFeedback.heavyImpact());
                await showQrCodeVerificationFailure(context, result);
              }
              continue;
            }

            if (contact != null && contactsVerified[contact.userId] == null) {
              contactsVerified[contact.userId] = ScannedVerifiedContact(
                contact: contact,
                verificationOk: true,
              );

              unawaited(HapticFeedback.heavyImpact());
              final context = cameraPreviewKey.currentContext;
              if (context != null && context.mounted) {
                await VerificationSuccessDialog.show(context, contact);
                onVerificationSuccessDismissed?.call(contact);
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
    } catch (e, stackTrace) {
      Log.error('QR-code processing failed: $e\n$stackTrace');
    } finally {
      _isBusy = false;
      setState?.call();
    }
  }
}
