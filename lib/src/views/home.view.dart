import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/camera_preview_components/camera_preview.dart';
import 'package:twonly/src/views/camera/camera_preview_controller_view.dart';
import 'package:twonly/src/views/chats/chat_list.view.dart';
import 'package:twonly/src/views/components/user_context_menu.dart';
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

  Timer? disableCameraTimer;
  bool initCameraStarted = true;

  CameraController? cameraController;
  ScreenshotController screenshotController = ScreenshotController();
  SelectedCameraDetails selectedCameraDetails = SelectedCameraDetails();

  bool onPageView(ScrollNotification notification) {
    disableCameraTimer?.cancel();
    if (notification.depth == 0 && notification is ScrollUpdateNotification) {
      setState(() {
        offsetFromOne = 1.0 - (homeViewPageController.page ?? 0);
        offsetRatio = offsetFromOne.abs();
      });
    }
    if (cameraController == null && !initCameraStarted && offsetRatio < 1) {
      initCameraStarted = true;
      selectCamera(selectedCameraDetails.cameraId, false, false);
    }
    if (offsetRatio == 1) {
      disableCameraTimer = Timer(const Duration(milliseconds: 500), () {
        cameraController?.dispose();
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
    selectCamera(0, true, false);
    initAsync();
  }

  @override
  void dispose() {
    selectNotificationStream.close();
    disableCameraTimer?.cancel();
    cameraController?.dispose();
    super.dispose();
  }

  Future<CameraController?> selectCamera(
      int sCameraId, bool init, bool enableAudio) async {
    final opts = await initializeCameraController(
        selectedCameraDetails, sCameraId, init, enableAudio);
    if (opts != null) {
      selectedCameraDetails = opts.$1;
      cameraController = opts.$2;
      initCameraStarted = false;
    }
    setState(() {});
    return cameraController;
  }

  Future<void> toggleSelectedCamera() async {
    await cameraController?.dispose();
    cameraController = null;
    await selectCamera((selectedCameraDetails.cameraId + 1) % 2, false, false);
  }

  Future<void> initAsync() async {
    final notificationAppLaunchDetails =
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
              HomeViewCameraPreview(
                controller: cameraController,
                screenshotController: screenshotController,
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
