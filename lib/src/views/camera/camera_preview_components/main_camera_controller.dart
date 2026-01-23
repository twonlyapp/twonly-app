import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/qr.pb.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/qr.dart';
import 'package:twonly/src/utils/screenshot.dart';
import 'package:twonly/src/views/camera/camera_preview_components/camera_preview_controller_view.dart';
import 'package:twonly/src/views/camera/camera_preview_components/face_filters.dart';
import 'package:twonly/src/views/camera/camera_preview_components/painters/barcode_detector_painter.dart';
import 'package:twonly/src/views/camera/camera_preview_components/painters/face_filters/beard_filter_painter.dart';
import 'package:twonly/src/views/camera/camera_preview_components/painters/face_filters/dog_filter_painter.dart';
import 'package:twonly/src/views/camera/camera_preview_components/painters/face_filters/face_filter_painter.dart';

class ScannedVerifiedContact {
  ScannedVerifiedContact({
    required this.contact,
    required this.verificationOk,
  });
  Contact contact;
  bool verificationOk;
}

class ScannedNewProfile {
  ScannedNewProfile({
    required this.profile,
    this.isLoading = false,
  });
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
  String? scannedUrl;
  GlobalKey zoomButtonKey = GlobalKey();
  GlobalKey cameraPreviewKey = GlobalKey();
  bool isSelectingFaceFilters = false;

  bool isSharePreviewIsShown = false;
  bool isVideoRecording = false;

  Uri? sharedLinkForPreview;

  void setSharedLinkForPreview(Uri url) {
    sharedLinkForPreview = url;
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
  CustomPaint? customPaint;
  CustomPaint? facePaint;
  Offset? focusPointOffset;

  FaceFilterType _currentFilterType = FaceFilterType.beardUpperLip;
  FaceFilterType get currentFilterType => _currentFilterType;

  Future<void> closeCamera() async {
    contactsVerified = {};
    scannedNewProfiles = {};
    scannedUrl = null;
    try {
      await cameraController?.stopImageStream();
    } catch (e) {
      Log.warn(e);
    }
    final cameraControllerTemp = cameraController;
    cameraController = null;
    await cameraControllerTemp?.dispose();
    initCameraStarted = false;
    selectedCameraDetails = SelectedCameraDetails();
  }

  Future<void> selectCamera(int sCameraId, bool init) async {
    initCameraStarted = true;

    var cameraId = sCameraId;
    if (cameraId >= gCameras.length) {
      Log.warn(
        'Trying to select a non existing camera $cameraId >= ${gCameras.length}',
      );
      return;
    }

    if (init) {
      for (; cameraId < gCameras.length; cameraId++) {
        if (gCameras[cameraId].lensDirection == CameraLensDirection.back) {
          break;
        }
      }
    }

    selectedCameraDetails.isZoomAble = false;
    if (selectedCameraDetails.cameraId != cameraId) {
      // switched camera so reset the scaleFactor
      selectedCameraDetails.scaleFactor = 1;
    }

    if (cameraController == null) {
      cameraController = CameraController(
        gCameras[cameraId],
        ResolutionPreset.high,
        enableAudio: await Permission.microphone.isGranted,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await cameraController?.initialize();
      await cameraController?.startImageStream(_processCameraImage);
    } else {
      await HapticFeedback.lightImpact();
      await cameraController?.stopImageStream();
      await cameraController?.setDescription(gCameras[cameraId]);
      await cameraController?.startImageStream(_processCameraImage);
    }

    await cameraController?.setZoomLevel(selectedCameraDetails.scaleFactor);
    await cameraController
        ?.lockCaptureOrientation(DeviceOrientation.portraitUp);
    await cameraController?.setFlashMode(
      selectedCameraDetails.isFlashOn ? FlashMode.always : FlashMode.off,
    );
    selectedCameraDetails.maxAvailableZoom =
        await cameraController?.getMaxZoomLevel() ?? 1;
    selectedCameraDetails.minAvailableZoom =
        await cameraController?.getMinZoomLevel() ?? 1;
    selectedCameraDetails
      ..isZoomAble = selectedCameraDetails.maxAvailableZoom !=
          selectedCameraDetails.minAvailableZoom
      ..cameraLoaded = true
      ..cameraId = cameraId;

    facePaint = null;
    customPaint = null;
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

    final dx = localPosition.dx / box.size.width;
    final dy = localPosition.dy / box.size.height;

    setState();

    await HapticFeedback.lightImpact();
    try {
      await cameraController?.setFocusPoint(Offset(dx, dy));
      await cameraController?.setFocusMode(FocusMode.auto);
    } catch (e) {
      Log.error(e);
    }

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
      // print('rotationCompensation: $rotationCompensation');
    }
    if (rotation == null) return null;
    // print('final rotation: $rotation');

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
      customPaint = CustomPaint(painter: painter);

      for (final barcode in barcodes) {
        if (barcode.displayValue != null) {
          if (barcode.displayValue!.startsWith('http://') ||
              barcode.displayValue!.startsWith('https://')) {
            scannedUrl = barcode.displayValue;
          }
        }
        if (barcode.rawBytes == null) continue;

        final profile = parseQrCodeData(barcode.rawBytes!);

        if (profile == null) continue;

        final contact =
            await twonlyDB.contactsDao.getContactById(profile.userId.toInt());

        if (contact != null && contact.accepted) {
          if (contactsVerified[contact.userId] == null) {
            final storedPublicKey =
                await getPublicKeyFromContact(contact.userId);
            if (storedPublicKey != null) {
              final verificationOk =
                  profile.publicIdentityKey.equals(storedPublicKey.toList());
              contactsVerified[contact.userId] = ScannedVerifiedContact(
                contact: contact,
                verificationOk: verificationOk,
              );
              if (verificationOk) {
                await twonlyDB.contactsDao.updateContact(
                  contact.userId,
                  const ContactsCompanion(verified: Value(true)),
                );
              }
              await HapticFeedback.heavyImpact();
              if (verificationOk) {
                globalRootScaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text(
                      globalRootScaffoldMessengerKey.currentContext?.lang
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
          }
        } else {
          if (profile.username != gUser.username) {
            if (scannedNewProfiles[profile.userId.toInt()] == null) {
              await HapticFeedback.heavyImpact();
              scannedNewProfiles[profile.userId.toInt()] = ScannedNewProfile(
                profile: profile,
              );
            }
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
        if (_currentFilterType == FaceFilterType.dogBrown) {
          painter = DogFilterPainter(
            faces,
            inputImage.metadata!.size,
            inputImage.metadata!.rotation,
            cameraController!.description.lensDirection,
          );
        } else if (_currentFilterType == FaceFilterType.beardUpperLip) {
          painter = BeardFilterPainter(
            faces,
            inputImage.metadata!.size,
            inputImage.metadata!.rotation,
            cameraController!.description.lensDirection,
          );
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
