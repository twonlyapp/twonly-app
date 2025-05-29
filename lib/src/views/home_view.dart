import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:logging/logging.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/camera_preview_components/camera_preview.dart';
import 'package:twonly/src/views/components/user_context_menu.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/views/gallery/gallery_main_view.dart';
import 'camera/camera_preview_controller_view.dart';
import 'chats/chat_list_view.dart';
import 'package:flutter/material.dart';

Function(int) globalUpdateOfHomeViewPageIndex = (a) {};

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    required this.initialPage,
  });
  final int initialPage;

  @override
  State<HomeView> createState() => HomeViewState();
}

class Shade extends StatelessWidget {
  const Shade({super.key, required this.opacity});
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

  final PageController homeViewPageController =
      PageController(keepPage: true, initialPage: 1);

  double buttonDiameter = 100.0;
  double offsetRatio = 0.0;
  double offsetFromOne = 0.0;

  Timer? disableCameraTimer;

  static CameraController? cameraController;
  static ScreenshotController screenshotController = ScreenshotController();
  static SelectedCameraDetails selectedCameraDetails = SelectedCameraDetails();

  bool onPageView(ScrollNotification notification) {
    disableCameraTimer?.cancel();
    if (notification.depth == 0 && notification is ScrollUpdateNotification) {
      setState(() {
        offsetFromOne = 1.0 - (homeViewPageController.page ?? 0);
        offsetRatio = offsetFromOne.abs();
      });
    }
    if (cameraController == null) {
      selectCamera(selectedCameraDetails.cameraId, false, false);
    }
    if (offsetRatio == 1) {
      disableCameraTimer = Timer(Duration(seconds: 2), () {
        cameraController?.dispose();
        cameraController = null;
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
    selectCamera(0, true, false);
    initAsync();
  }

  @override
  void dispose() {
    selectNotificationStream.close();
    disableCameraTimer?.cancel();
    super.dispose();
  }

  Future selectCamera(int sCameraId, bool init, bool enableAudio) async {
    if (sCameraId >= gCameras.length) return;
    if (init) {
      for (; sCameraId < gCameras.length; sCameraId++) {
        if (gCameras[sCameraId].lensDirection == CameraLensDirection.back) {
          break;
        }
      }
    }
    selectedCameraDetails.isZoomAble = false;
    if (selectedCameraDetails.cameraId != sCameraId) {
      // switch between front and back
      selectedCameraDetails.scaleFactor = 1;
    }

    cameraController = CameraController(
      gCameras[sCameraId],
      ResolutionPreset.high,
      enableAudio: enableAudio,
    );

    await cameraController?.initialize().then((_) async {
      await cameraController?.setZoomLevel(selectedCameraDetails.scaleFactor);
      await cameraController
          ?.lockCaptureOrientation(DeviceOrientation.portraitUp);
      cameraController?.setFlashMode(
          selectedCameraDetails.isFlashOn ? FlashMode.always : FlashMode.off);
      await cameraController?.getMaxZoomLevel().then(
          (double value) => selectedCameraDetails.maxAvailableZoom = value);
      await cameraController?.getMinZoomLevel().then(
          (double value) => selectedCameraDetails.minAvailableZoom = value);
      selectedCameraDetails.isZoomAble =
          selectedCameraDetails.maxAvailableZoom !=
              selectedCameraDetails.minAvailableZoom;
      setState(() {
        selectedCameraDetails.cameraLoaded = true;
        selectedCameraDetails.cameraId = sCameraId;
      });
    }).catchError((Object e) {
      Logger("home_view.dart").shout("$e");
    });
    setState(() {});
  }

  Future toggleSelectedCamera() async {
    selectCamera((selectedCameraDetails.cameraId + 1) % 2, false, false);
  }

  Future initAsync() async {
    var notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails != null) {
      if (notificationAppLaunchDetails.didNotificationLaunchApp) {
        globalUpdateOfHomeViewPageIndex(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PieCanvas(
      theme: getPieCanvasTheme(context),
      child: Scaffold(
        body: GestureDetector(
          onDoubleTap: offsetRatio == 0 ? toggleSelectedCamera : null,
          child: Stack(
            children: <Widget>[
              CameraPreviewWidget(),
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
                      ChatListView(),
                      Container(),
                      GalleryMainView(),
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
                    opacity: (1 - (offsetRatio * 4) % 1),
                    child: CameraPreviewControllerView(
                      selectCamera: selectCamera,
                    ),
                  )),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          unselectedIconTheme: IconThemeData(
              color:
                  Theme.of(context).colorScheme.inverseSurface.withAlpha(150)),
          selectedIconTheme: IconThemeData(
              color: Theme.of(context).colorScheme.inverseSurface),
          items: [
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.solidComments),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.camera),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.photoFilm),
              label: "",
            ),
          ],
          onTap: (int index) {
            activePageIdx = index;
            setState(() {
              homeViewPageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 100),
                curve: Curves.bounceIn,
              );
            });
          },
          currentIndex: activePageIdx,
        ),
      ),
    );
  }
}
