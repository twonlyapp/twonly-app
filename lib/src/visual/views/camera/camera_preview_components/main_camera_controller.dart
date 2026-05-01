import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/qr.pb.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/qr.utils.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview_controller_view.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/face_filters.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/painters/barcode_detector_painter.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/painters/face_filters/beard_filter_painter.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/painters/face_filters/dog_filter_painter.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/painters/face_filters/face_filter_painter.dart';

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
  late void Function() setState;
  CameraController? cameraController;
  ScreenshotController screenshotController = ScreenshotController();
  SelectedCameraDetails selectedCameraDetails = SelectedCameraDetails();
  bool initCameraStarted = true;
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

  Uri? sharedLinkForPreview;

  void setSharedLinkForPreview(Uri? url) {
    sharedLinkForPreview = url;
    setState();
  }

  void onImageSend() {
    scannedUrl = '';
    setState();
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

  Future<void> closeCamera() async {
    contactsVerified = {};
    scannedNewProfiles = {};
    scannedUrl = null;
    try {
      await cameraController?.stopImageStream();
      // ignore: empty_catches
    } catch (e) {}
    final cameraControllerTemp = cameraController;
    cameraController = null;
    // prevents: CameraException(Disposed CameraController, buildPreview() was called on a disposed CameraController.)
    Future.delayed(const Duration(milliseconds: 100), () async {
      await cameraControllerTemp?.dispose();
    });
    initCameraStarted = false;
    selectedCameraDetails = SelectedCameraDetails();
  }

  Future<void> selectCamera(int sCameraId, bool init) async {
    initCameraStarted = true;

    if (AppEnvironment.cameras.isEmpty) {
      AppEnvironment.cameras = await availableCameras();
    }

    var cameraId = sCameraId;
    if (cameraId >= AppEnvironment.cameras.length) {
      Log.warn(
        'Trying to select a non existing camera $cameraId >= ${AppEnvironment.cameras.length}',
      );
      return;
    }

    if (init) {
      for (; cameraId < AppEnvironment.cameras.length; cameraId++) {
        if (AppEnvironment.cameras[cameraId].lensDirection ==
            CameraLensDirection.back) {
          break;
        }
      }
    }

    selectedCameraDetails.isZoomAble = false;

    if (cameraController == null) {
      cameraController = CameraController(
        AppEnvironment.cameras[cameraId],
        ResolutionPreset.high,
        enableAudio: await Permission.microphone.isGranted,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await cameraController?.initialize();
      await cameraController?.startImageStream(_processCameraImage);
      await cameraController?.setZoomLevel(selectedCameraDetails.scaleFactor);
      if (userService.currentUser.videoStabilizationEnabled && !kDebugMode) {
        await cameraController?.setVideoStabilizationMode(
          VideoStabilizationMode.level1,
        );
      }
    } else {
      try {
        if (!isVideoRecording) {
          await cameraController?.stopImageStream();
        }
      } catch (e) {
        Log.info(e);
      }
      selectedCameraDetails.scaleFactor = 1;

      await cameraController?.setZoomLevel(1);
      await cameraController?.setDescription(AppEnvironment.cameras[cameraId]);
      try {
        if (!isVideoRecording) {
          await cameraController?.startImageStream(_processCameraImage);
        }
      } catch (e) {
        Log.info(e);
      }
    }

    await cameraController?.lockCaptureOrientation(
      DeviceOrientation.portraitUp,
    );
    await cameraController?.setFlashMode(
      selectedCameraDetails.isFlashOn ? FlashMode.always : FlashMode.off,
    );
    selectedCameraDetails.maxAvailableZoom =
        await cameraController?.getMaxZoomLevel() ?? 1;
    selectedCameraDetails.minAvailableZoom =
        await cameraController?.getMinZoomLevel() ?? 1;
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
    setState();
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

    setState();

    await HapticFeedback.lightImpact();
    try {
      await cameraController?.setFocusPoint(Offset(dx, dy));
      await cameraController?.setFocusMode(FocusMode.auto);
    } catch (e) {
      if (e is CameraException &&
          (e.code == 'setFocusPointFailed' || e.code == 'setFocusModeFailed')) {
        Log.info('Focus point or mode not supported on this device');
      } else {
        Log.error(e);
      }
    }

    // display the focus point at least 500ms
    await Future.delayed(const Duration(milliseconds: 500));

    focusPointOffset = null;
    setState();
  }

  void setFilter(FaceFilterType type) {
    _currentFilterType = type;
    if (_currentFilterType == FaceFilterType.none) {
      faceFilterPainter = null;
      facePaint = null;
      _isBusyFaces = false;
    }
    setState();
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
    _processBarcode(inputImage);
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
    if (cameraController == null) return null;
    final camera = cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[cameraController!.value.deviceOrientation];
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
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null &&
        cameraController != null) {
      final painter = BarcodeDetectorPainter(
        barcodes,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        cameraController!.description.lensDirection,
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

        if (link.startsWith(QrCodeUtils.linkPrefix)) {
          if (_handledProfileLinks.contains(link)) continue;
          _handledProfileLinks.add(link);

          final res = await QrCodeUtils.handleQrCodeLink(link);
          if (res == null) continue;
          final (profile, contact, verificationOk) = res;

          if (contact == null) {
            if (scannedNewProfiles[profile.userId.toInt()] == null) {
              await HapticFeedback.heavyImpact();
              scannedNewProfiles[profile.userId.toInt()] = ScannedNewProfile(
                profile: profile,
              );
            }
            continue;
          }

          if (contactsVerified[contact.userId] == null) {
            contactsVerified[contact.userId] = ScannedVerifiedContact(
              contact: contact,
              verificationOk: verificationOk,
            );

            await HapticFeedback.heavyImpact();
            if (verificationOk) {
              AppGlobalKeys.scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text(
                    AppGlobalKeys.scaffoldMessengerKey.currentContext?.lang
                            .verifiedPublicKey(
                              getContactDisplayName(contact),
                            ) ??
                        '',
                  ),
                  duration: const Duration(seconds: 6),
                ),
              );
            }
          }
          continue;
        }

        if (link.startsWith('http://') || link.startsWith('https://')) {
          scannedUrl = link;
          if (sharedLinkForPreview == null) {
            timeSharedLinkWasSetWithQr = clock.now();
            setSharedLinkForPreview(Uri.parse(scannedUrl!));
          }
        }
      }
    }
    _isBusy = false;
    setState();
  }

  Future<void> _processFaces(InputImage inputImage) async {
    if (_isBusyFaces) return;
    _isBusyFaces = true;
    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null &&
        cameraController != null) {
      if (faces.isNotEmpty) {
        CustomPainter? painter;
        switch (_currentFilterType) {
          case FaceFilterType.dogBrown:
            painter = DogFilterPainter(
              faces,
              inputImage.metadata!.size,
              inputImage.metadata!.rotation,
              cameraController!.description.lensDirection,
            );
          case FaceFilterType.beardUpperLipGreen:
            painter = BeardFilterPainter(
              _currentFilterType,
              faces,
              inputImage.metadata!.size,
              inputImage.metadata!.rotation,
              cameraController!.description.lensDirection,
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
    setState();
  }
}
