import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/services/intent/links.intent.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/camera_preview_components/camera_preview.dart';
import 'package:twonly/src/views/camera/camera_preview_components/camera_preview_controller_view.dart';
import 'package:twonly/src/views/camera/camera_preview_components/main_camera_controller.dart';
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

  final MainCameraController _mainCameraController = MainCameraController();

  final PageController homeViewPageController = PageController(initialPage: 1);
  late StreamSubscription<List<SharedFile>> _intentStreamSub;
  late StreamSubscription<Uri> _deepLinkSub;

  double buttonDiameter = 100;
  double offsetRatio = 0;
  double offsetFromOne = 0;
  double lastChange = 0;

  Timer? disableCameraTimer;

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
    if (_mainCameraController.cameraController == null &&
        !_mainCameraController.initCameraStarted &&
        offsetRatio < 1) {
      unawaited(
        _mainCameraController.selectCamera(
          _mainCameraController.selectedCameraDetails.cameraId,
          false,
        ),
      );
    }
    if (offsetRatio == 1) {
      disableCameraTimer = Timer(const Duration(milliseconds: 500), () async {
        await _mainCameraController.closeCamera();
        disableCameraTimer = null;
      });
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _mainCameraController.setState = () {
      if (mounted) setState(() {});
    };
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
    unawaited(_mainCameraController.selectCamera(0, true));
    unawaited(initAsync());

    // Subscribe to all events (initial link and further)
    _deepLinkSub = AppLinks().uriLinkStream.listen((uri) async {
      if (mounted) await handleIntentUrl(context, uri);
    });

    _intentStreamSub = FlutterSharingIntent.instance.getMediaStream().listen(
      (f) {
        if (mounted) handleIntentSharedFile(context, f);
      },
      // ignore: inference_failure_on_untyped_parameter
      onError: (err) {
        Log.error('getIntentDataStream error: $err');
      },
    );

    FlutterSharingIntent.instance.getInitialSharing().then((f) {
      if (mounted) handleIntentSharedFile(context, f);
    });
  }

  @override
  void dispose() {
    unawaited(selectNotificationStream.close());
    disableCameraTimer?.cancel();
    _mainCameraController.closeCamera();
    _intentStreamSub.cancel();
    _deepLinkSub.cancel();
    super.dispose();
  }

  Future<void> initAsync() async {
    final notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (widget.initialPage == 0 ||
        (notificationAppLaunchDetails != null &&
            notificationAppLaunchDetails.didNotificationLaunchApp)) {
      globalUpdateOfHomeViewPageIndex(0);
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
        onDoubleTap: offsetRatio == 0
            ? _mainCameraController.toggleSelectedCamera
            : null,
        child: Stack(
          children: <Widget>[
            MainCameraPreview(mainCameraController: _mainCameraController),
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
                  mainController: _mainCameraController,
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
