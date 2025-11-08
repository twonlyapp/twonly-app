import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/camera_preview_components/camera_preview.dart';
import 'package:twonly/src/views/camera/camera_preview_controller_view.dart';
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
    cameraController?.dispose();
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
    await cameraController!.dispose();
    cameraController = null;
    await selectCamera((selectedCameraDetails.cameraId + 1) % 2, false);
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
      final service = await MediaFileService.fromMedia(draftMedia);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShareImageEditorView(
            mediaFileService: service,
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
