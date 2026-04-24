import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/providers/routing.provider.dart';
import 'package:twonly/src/services/intent/links.intent.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview_controller_view.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/main_camera_controller.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor.view.dart';
import 'package:twonly/src/visual/views/chats/chat_list.view.dart';
import 'package:twonly/src/visual/views/memories/memories.view.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    required this.initialPage,
    super.key,
  });
  final int initialPage;

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  int _activePageIdx = 1;
  double _offsetRatio = 0;
  double _offsetFromOne = 0;
  Timer? _disableCameraTimer;

  final MainCameraController _mainCameraController = MainCameraController();
  final PageController _homeViewPageController = PageController(initialPage: 1);

  late StreamSubscription<List<SharedFile>> _intentStreamSub;
  late StreamSubscription<Uri> _deepLinkSub;

  static final streamHomeViewPageIndex = StreamController<int>.broadcast();

  @override
  void initState() {
    super.initState();
    _mainCameraController.setState = () {
      if (mounted) setState(() {});
    };

    streamHomeViewPageIndex.stream.listen((index) {
      _homeViewPageController.jumpToPage(index);
      setState(() {
        _activePageIdx = index;
      });
    });

    selectNotificationStream.stream.listen((response) async {
      if (response.payload != null &&
          response.payload!.startsWith(Routes.chats) &&
          response.payload! != Routes.chats) {
        await routerProvider.push(response.payload!);
      }
      streamHomeViewPageIndex.add(0);
    });

    unawaited(_mainCameraController.selectCamera(0, true));
    unawaited(_initAsync());

    handleIntentUrl(
      context,
      Uri.parse(
        'https://me.twonly.eu/qr/#EAAauAEIgLDN0Nm7oKh0EghoYWhoaGhoaBohBRZQ8w_zpm1v7SRTdc8GEOMAxuf1caGDlBa-v0ZiTw9qIiEF05juEs1c3yw0STiSwQR7lowDX5hBaxN4YFR0HhkopGIoudTO5wIyQFQRtU1aO7P7O5s2ekB1ppAost3iQQizwhFObjOLgHQnpwcnwEONXZzSADYqCeEoNcvyE45w0v21z1Imhozk3Q44oI0GQhA9U_chIJwwZ7J9fpeXODZF',
      ),
    );

    // Subscribe to all events (initial link and further)
    _deepLinkSub = AppLinks().uriLinkStream.listen((uri) async {
      if (!mounted) return;
      Log.info('Got link via app links: ${uri.scheme}');
      if (!await handleIntentUrl(context, uri)) {
        if (uri.scheme.startsWith('http')) {
          _mainCameraController.setSharedLinkForPreview(uri);
        }
      }
    });

    _intentStreamSub = initIntentStreams(
      context,
      _mainCameraController.setSharedLinkForPreview,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPage == 1 &&
              !userService.currentUser.startWithCameraOpen ||
          widget.initialPage == 0) {
        streamHomeViewPageIndex.add(0);
      }
    });
  }

  Future<void> _initAsync() async {
    final notificationAppLaunchDetails = await flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();

    if (widget.initialPage == 0 ||
        (notificationAppLaunchDetails != null &&
            notificationAppLaunchDetails.didNotificationLaunchApp)) {
      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        final payload =
            notificationAppLaunchDetails?.notificationResponse?.payload;
        if (payload != null &&
            payload.startsWith(Routes.chats) &&
            payload != Routes.chats) {
          await routerProvider.push(payload);
          streamHomeViewPageIndex.add(0);
        }
        if (payload == Routes.chats) {
          streamHomeViewPageIndex.add(0);
        }
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
  void dispose() {
    selectNotificationStream.close();
    streamHomeViewPageIndex.close();
    _disableCameraTimer?.cancel();
    _mainCameraController.closeCamera();
    _intentStreamSub.cancel();
    _deepLinkSub.cancel();
    super.dispose();
  }

  bool _onPageView(ScrollNotification notification) {
    _disableCameraTimer?.cancel();

    if (notification.depth == 0 && notification is ScrollUpdateNotification) {
      setState(() {
        _offsetFromOne = 1.0 - (_homeViewPageController.page ?? 0);
        _offsetRatio = _offsetFromOne.abs();
      });
    }

    if (_mainCameraController.cameraController == null &&
        !_mainCameraController.initCameraStarted &&
        _offsetRatio < 1) {
      unawaited(
        _mainCameraController.selectCamera(
          _mainCameraController.selectedCameraDetails.cameraId,
          false,
        ),
      );
    }

    if (_offsetRatio == 1) {
      _disableCameraTimer = Timer(const Duration(milliseconds: 500), () async {
        await _mainCameraController.closeCamera();
        _mainCameraController.sharedLinkForPreview = null;
        _disableCameraTimer = null;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onDoubleTap: _offsetRatio == 0
            ? _mainCameraController.onDoubleTap
            : null,
        onTapDown: _offsetRatio == 0 ? _mainCameraController.onTapDown : null,
        child: Stack(
          children: <Widget>[
            MainCameraPreview(mainCameraController: _mainCameraController),
            Positioned.fill(
              child: Opacity(
                opacity: _offsetRatio,
                child: Container(
                  color: context.color.surface,
                ),
              ),
            ),
            NotificationListener<ScrollNotification>(
              onNotification: _onPageView,
              child: Positioned.fill(
                child: PageView(
                  controller: _homeViewPageController,
                  onPageChanged: (index) {
                    setState(() {
                      _activePageIdx = index;
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
              bottom: (_offsetRatio > 0.25)
                  ? MediaQuery.sizeOf(context).height * 2
                  : 0,
              child: Opacity(
                opacity: 1 - (_offsetRatio * 4) % 1,
                child: CameraPreviewControllerView(
                  mainController: _mainCameraController,
                  isVisible:
                      ((1 - (_offsetRatio * 4) % 1) == 1) &&
                      _activePageIdx == 1,
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
        onTap: (index) async {
          _activePageIdx = index;
          await _homeViewPageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 100),
            curve: Curves.bounceIn,
          );
          if (mounted) setState(() {});
        },
        currentIndex: _activePageIdx,
      ),
    );
  }
}
