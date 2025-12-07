import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/camera_preview_components/camera_preview.dart';
import 'package:twonly/src/views/camera/camera_preview_controller_view.dart';
import 'package:twonly/src/views/camera/painters/barcode_detector_painter.dart';
import 'package:twonly/src/views/camera/share_image_editor_view.dart';
import 'package:twonly/src/views/chats/chat_list.view.dart';
import 'package:twonly/src/views/memories/memories.view.dart';

void Function(int) globalUpdateOfHomeViewPageIndex = (a) {};

class HomeView extends StatefulWidget {
  const HomeView({
    required this.initialPage,
    super.key,
  });
  final int initialPage;

  @override
  State<HomeView> createState() => HomeViewState();
}

class Shade extends StatelessWidget {
  const Shade({required this.opacity, super.key});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: Container(
          color: context.color.surface,
        ),
      ),
    );
  }
}

class HomeViewState extends State<HomeView> {
  int activePageIdx = 0;

  final PageController homeViewPageController = PageController(initialPage: 1);

  double buttonDiameter = 100;
  double offsetRatio = 0;
  double offsetFromOne = 0;
  double lastChange = 0;

  Timer? disableCameraTimer;
  bool initCameraStarted = true;

  CameraController? cameraController;
  ScreenshotController screenshotController = ScreenshotController();
  SelectedCameraDetails selectedCameraDetails = SelectedCameraDetails();

  bool onPageView(ScrollNotification notification) {
    disableCameraTimer?.cancel();
    if (notification.depth == 0 && notification is ScrollUpdateNotification) {
      final page = homeViewPageController.page ?? 0;
      lastChange = page;
      setState(() {
        offsetFromOne = 1.0 - (homeViewPageController.page ?? 0);
        offsetRatio = offsetFromOne.abs();
      });
    }
    if (cameraController == null && !initCameraStarted && offsetRatio < 1) {
      initCameraStarted = true;
      unawaited(selectCamera(selectedCameraDetails.cameraId, false));
    }
    if (offsetRatio == 1) {
      disableCameraTimer = Timer(const Duration(milliseconds: 500), () async {
        await cameraController?.dispose();
        cameraController = null;
        selectedCameraDetails = SelectedCameraDetails();
        disableCameraTimer = null;
      });
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    activePageIdx = widget.initialPage;
    globalUpdateOfHomeViewPageIndex = (index) {
      homeViewPageController.jumpToPage(index);
      setState(() {
        activePageIdx = index;
      });
    };
    selectNotificationStream.stream
        .listen((NotificationResponse? response) async {
      globalUpdateOfHomeViewPageIndex(0);
    });
    unawaited(selectCamera(0, true));
    unawaited(initAsync());
  }

  @override
  void dispose() {
    unawaited(selectNotificationStream.close());
    disableCameraTimer?.cancel();
    cameraController?.stopImageStream();
    cameraController?.dispose();
    cameraController = null;
    super.dispose();
  }

  Future<CameraController?> selectCamera(int sCameraId, bool init) async {
    final opts = await initializeCameraController(
      selectedCameraDetails,
      sCameraId,
      init,
    );
    if (opts != null) {
      selectedCameraDetails = opts.$1;
      cameraController = opts.$2;
      initCameraStarted = false;
    }
    if (cameraController?.description.lensDirection ==
        CameraLensDirection.back) {
      await cameraController?.startImageStream(_processCameraImage);
    }
    setState(() {});
    return cameraController;
  }

  /// same function also in camera_send_to_view
  Future<void> toggleSelectedCamera() async {
    if (cameraController == null) return;
    // do not allow switching camera when recording
    if (cameraController!.value.isRecordingVideo) {
      return;
    }
    await cameraController!.stopImageStream();
    await cameraController!.dispose();
    cameraController = null;
    await selectCamera((selectedCameraDetails.cameraId + 1) % 2, false);
  }

  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;

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

    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/android/src/main/java/com/google_mlkit_commons/InputImageConverter.java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/ios/Classes/MLKVisionImage%2BFlutterPlugin.m
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/example/lib/vision_detector_views/painters/coordinates_translator.dart
    final camera = cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    // print(
    //     'lensDirection: ${camera.lensDirection}, sensorOrientation: $sensorOrientation, ${_controller?.value.deviceOrientation} ${_controller?.value.lockedCaptureOrientation} ${_controller?.value.isCaptureOrientationLocked}');
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
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final barcodes = await _barcodeScanner.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null &&
        cameraController != null) {
      final painter = BarcodeDetectorPainter(
          barcodes,
          inputImage.metadata!.size,
          inputImage.metadata!.rotation,
          cameraController!.description.lensDirection);
      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Barcodes found: ${barcodes.length}\n\n';
      for (final barcode in barcodes) {
        text += 'Barcode: ${barcode.rawValue}\n\n';
      }
      _text = text;
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> initAsync() async {
    final notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails != null) {
      if (notificationAppLaunchDetails.didNotificationLaunchApp) {
        globalUpdateOfHomeViewPageIndex(0);
      }
    }

    final draftMedia = await twonlyDB.mediaFilesDao.getDraftMediaFile();
    if (draftMedia != null) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShareImageEditorView(
            mediaFileService: MediaFileService(draftMedia),
            sharedFromGallery: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onDoubleTap: offsetRatio == 0 ? toggleSelectedCamera : null,
        child: Stack(
          children: <Widget>[
            HomeViewCameraPreview(
              controller: cameraController,
              screenshotController: screenshotController,
              customPaint: _customPaint,
            ),
            Shade(
              opacity: offsetRatio,
            ),
            NotificationListener<ScrollNotification>(
              onNotification: onPageView,
              child: Positioned.fill(
                child: PageView(
                  controller: homeViewPageController,
                  onPageChanged: (index) {
                    setState(() {
                      activePageIdx = index;
                    });
                  },
                  children: [
                    const ChatListView(),
                    Container(),
                    const MemoriesView(),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: (offsetRatio > 0.25)
                  ? MediaQuery.sizeOf(context).height * 2
                  : 0,
              child: Opacity(
                opacity: 1 - (offsetRatio * 4) % 1,
                child: CameraPreviewControllerView(
                  cameraController: cameraController,
                  screenshotController: screenshotController,
                  selectedCameraDetails: selectedCameraDetails,
                  selectCamera: selectCamera,
                  isVisible:
                      ((1 - (offsetRatio * 4) % 1) == 1) && activePageIdx == 1,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        unselectedIconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.inverseSurface.withAlpha(150),
        ),
        selectedIconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.inverseSurface,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.solidComments),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.camera),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.photoFilm),
            label: '',
          ),
        ],
        onTap: (int index) async {
          activePageIdx = index;
          await homeViewPageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 100),
            curve: Curves.bounceIn,
          );
          if (mounted) setState(() {});
        },
        currentIndex: activePageIdx,
      ),
    );
  }
}
