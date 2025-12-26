import 'dart:io';
import 'package:camera/camera.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/qr.pb.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/qr.dart';
import 'package:twonly/src/utils/screenshot.dart';
import 'package:twonly/src/views/camera/camera_preview_components/camera_preview_controller_view.dart';
import 'package:twonly/src/views/camera/painters/barcode_detector_painter.dart';

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

  Future<CameraController?> selectCamera(int sCameraId, bool init) async {
    initCameraStarted = true;
    final opts = await initializeCameraController(
      selectedCameraDetails,
      sCameraId,
      init,
    );
    if (opts != null) {
      selectedCameraDetails = opts.$1;
      cameraController = opts.$2;
    }
    if (cameraController?.description.lensDirection ==
        CameraLensDirection.back) {
      await cameraController?.startImageStream(_processCameraImage);
    }
    setState();
    return cameraController;
  }

  Future<void> toggleSelectedCamera() async {
    if (cameraController == null) return;
    // do not allow switching camera when recording
    if (cameraController!.value.isRecordingVideo) {
      return;
    }
    try {
      await cameraController!.stopImageStream();
    } catch (e) {
      Log.warn(e);
    }
    await cameraController!.dispose();
    cameraController = null;
    await selectCamera((selectedCameraDetails.cameraId + 1) % 2, false);
  }

  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isBusy = false;
  CustomPaint? customPaint;

  final Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    _processImage(inputImage);
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

  Future<void> _processImage(InputImage inputImage) async {
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
}
