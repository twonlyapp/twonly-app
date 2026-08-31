import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/providers/routing.provider.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/native.notifications.dart';
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

class HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  int _activePageIdx = 1;
  double _offsetRatio = 0;
  double _offsetFromOne = 0;
  bool _isBottomNavVisible = true;
  Timer? _disableCameraTimer;
  bool _startPreloading = false;

  final MainCameraController _mainCameraController = MainCameraController();
  late final PageController _homeViewPageController;

  StreamSubscription<Uri>? _sharedLinkSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<int>? _homeViewPageIndexSub;
  StreamSubscription<NotificationResponse>? _selectNotificationSub;
  StreamSubscription<NativeNotificationTap>? _nativeNotificationSub;
  StreamSubscription<(String, MediaType)>? _sharedMediaSub;

  static Uri? pendingSharedLink;
  static (String, MediaType)? pendingSharedMedia;
  static final streamHomeViewPageIndex = StreamController<int>.broadcast();
  static final streamSharedLink = StreamController<Uri>.broadcast();
  static final streamSharedMedia =
      StreamController<(String, MediaType)>.broadcast();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    var initialPage = widget.initialPage;
    if (HomeViewState.pendingSharedLink != null) {
      initialPage = 1;
    } else if (HomeViewState.pendingSharedMedia != null) {
      initialPage = 0;
    } else if (initialPage == 1 &&
        !userService.currentUser.startWithCameraOpen) {
      initialPage = 0;
    }
    _activePageIdx = initialPage;
    _offsetFromOne = 1.0 - initialPage;
    _offsetRatio = _offsetFromOne.abs();
    _homeViewPageController = PageController(initialPage: initialPage);

    _mainCameraController.setState = () {
      if (mounted) setState(() {});
    };

    _homeViewPageIndexSub = streamHomeViewPageIndex.stream.listen((index) {
      if (_homeViewPageController.hasClients) {
        _homeViewPageController.jumpToPage(index);
      }
      setState(() {
        _activePageIdx = index;
        _offsetFromOne = 1.0 - index;
        _offsetRatio = _offsetFromOne.abs();
      });
      if (index != 1) {
        unawaited(_mainCameraController.closeCamera());
      }
    });

    _selectNotificationSub = selectNotificationStream.stream.listen((
      response,
    ) async {
      if (response.payload != null &&
          response.payload!.startsWith(Routes.chats) &&
          response.payload! != Routes.chats) {
        routerProvider.go(response.payload!);
      }
      streamHomeViewPageIndex.add(0);
    });

    _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      Log.info('Opened app from iOS/Remote push notification tap.');
      _openNotification(
        conversationId: _notificationDataValue(message, 'conversation_id'),
        kind: _notificationDataValue(message, 'notification_kind'),
      );
    });

    _nativeNotificationSub = NativeNotificationService.taps.listen(
      _openNativeNotification,
    );

    _sharedLinkSub = streamSharedLink.stream.listen((uri) {
      HomeViewState.pendingSharedLink = null;
      _mainCameraController.setSharedLinkForPreview(uri);
      Permission.camera.isGranted.then((hasPermission) {
        if (hasPermission && mounted) {
          unawaited(_mainCameraController.selectCamera(0, true));
        }
      });
    });

    _sharedMediaSub = streamSharedMedia.stream.listen((media) async {
      HomeViewState.pendingSharedMedia = null;
      final type = media.$2;
      final filePath = media.$1;

      final mediaId = await RustApi.initializeMediaUpload(
        mediaType: type.name,
        displayLimitInMilliseconds: userService.currentUser.defaultShowTime,
        isDraftMedia: false,
      );
      final newMediaService = await MediaFileService.fromMediaId(mediaId);
      if (newMediaService == null) {
        Log.error('Could not create new media file for intent shared file');
        return;
      }

      final file = File(filePath);
      if (!file.existsSync()) {
        Log.error('The shared intent file does not exist.');
        return;
      }
      file.copySync(newMediaService.originalPath.path);
      if (!mounted) return;

      await context.navPush(
        ShareImageEditorView(
          mediaFileService: newMediaService,
          sharedFromGallery: true,
        ),
      );
    });

    if (HomeViewState.pendingSharedLink != null) {
      final link = HomeViewState.pendingSharedLink!;
      HomeViewState.pendingSharedLink = null;
      _mainCameraController.setSharedLinkForPreview(link);
    }

    if (HomeViewState.pendingSharedMedia != null) {
      final media = HomeViewState.pendingSharedMedia!;
      HomeViewState.pendingSharedMedia = null;
      streamSharedMedia.add(media);
    }

    if (initialPage == 1) {
      Permission.camera.isGranted.then((hasPermission) {
        if (hasPermission && mounted) {
          unawaited(_mainCameraController.selectCamera(0, true));
        }
      });
    }

    unawaited(_initAsync());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mainCameraController.sharedLinkForPreview == null &&
          ((widget.initialPage == 1 &&
                  !userService.currentUser.startWithCameraOpen) ||
              widget.initialPage == 0)) {
        streamHomeViewPageIndex.add(0);
      }
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _startPreloading = true;
          });
        }
      });
    });
  }

  void _openNativeNotification(NativeNotificationTap tap) {
    Log.info('Opened app from a native push notification tap.');
    _openNotification(conversationId: tap.conversationId, kind: tap.kind);
  }

  void _openNotification({String? conversationId, String? kind}) {
    if (conversationId != null &&
        NativeNotificationService.opensConversation(kind)) {
      routerProvider.go(Routes.chatsMessages(conversationId));
    }
    streamHomeViewPageIndex.add(0);
  }

  String? _notificationDataValue(RemoteMessage message, String key) {
    final value = message.data[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  Future<void> _initAsync() async {
    final initialNativeTap =
        await NativeNotificationService.consumeInitialTap();
    if (initialNativeTap != null) {
      _openNativeNotification(initialNativeTap);
    }

    final notificationAppLaunchDetails = await flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();

    RemoteMessage? initialRemoteMessage;
    try {
      initialRemoteMessage = await FirebaseMessaging.instance
          .getInitialMessage();
    } catch (e) {
      Log.error('Could not get initial Firebase message: $e');
    }

    if (widget.initialPage == 0 ||
        initialRemoteMessage != null ||
        (notificationAppLaunchDetails != null &&
            notificationAppLaunchDetails.didNotificationLaunchApp)) {
      if (initialRemoteMessage != null) {
        Log.info('App launched from iOS/Remote push notification tap.');
        _openNotification(
          conversationId: _notificationDataValue(
            initialRemoteMessage,
            'conversation_id',
          ),
          kind: _notificationDataValue(
            initialRemoteMessage,
            'notification_kind',
          ),
        );
      } else if (notificationAppLaunchDetails?.didNotificationLaunchApp ??
          false) {
        final payload =
            notificationAppLaunchDetails?.notificationResponse?.payload;
        if (payload != null &&
            payload.startsWith(Routes.chats) &&
            payload != Routes.chats) {
          routerProvider.go(payload);
        }
        streamHomeViewPageIndex.add(0);
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
    WidgetsBinding.instance.removeObserver(this);
    _onMessageOpenedAppSub?.cancel();
    _homeViewPageIndexSub?.cancel();
    _selectNotificationSub?.cancel();
    _nativeNotificationSub?.cancel();
    _disableCameraTimer?.cancel();
    _mainCameraController.setState = null;
    _mainCameraController.closeCamera();
    _sharedLinkSub?.cancel();
    _sharedMediaSub?.cancel();
    super.dispose();
  }

  bool _isViewActive() {
    if (!mounted) return false;
    return ModalRoute.of(context)?.isCurrent ?? false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (AppState.hasCameraPermissions &&
          _offsetRatio < 1 &&
          !_mainCameraController.isSharePreviewIsShown &&
          _isViewActive() &&
          _mainCameraController.cameraController == null &&
          !_mainCameraController.initCameraStarted) {
        unawaited(
          _mainCameraController.selectCamera(
            _mainCameraController.selectedCameraDetails.cameraId,
            false,
          ),
        );
      }
    } else if (state == AppLifecycleState.paused) {
      unawaited(_mainCameraController.closeCamera());
    }
  }

  bool _onPageView(ScrollNotification notification) {
    _disableCameraTimer?.cancel();

    if (notification.depth > 0 && notification.metrics.axis == Axis.vertical) {
      final canScroll =
          notification.metrics.maxScrollExtent >
          notification.metrics.minScrollExtent;
      if (!canScroll) {
        if (!_isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = true;
          });
        }
      } else {
        if (_activePageIdx == 2 &&
            notification.metrics.pixels < 100 &&
            !_isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = true;
          });
        } else if (notification is ScrollUpdateNotification) {
          final delta = notification.scrollDelta ?? 0;
          if (delta > 5 &&
              _isBottomNavVisible &&
              (_activePageIdx != 2 || notification.metrics.pixels >= 100)) {
            setState(() {
              _isBottomNavVisible = false;
            });
          } else if (delta < -5 && !_isBottomNavVisible) {
            setState(() {
              _isBottomNavVisible = true;
            });
          }
        }
      }
    }

    if (notification.depth == 0) {
      setState(() {
        _offsetFromOne = 1.0 - (_homeViewPageController.page ?? 0);
        _offsetRatio = _offsetFromOne.abs();
        final pageIndex = _homeViewPageController.page?.round();
        if (pageIndex != null && pageIndex != _activePageIdx) {
          _activePageIdx = pageIndex;
        }
      });
    }

    if (AppState.hasCameraPermissions &&
        _mainCameraController.cameraController == null &&
        !_mainCameraController.initCameraStarted &&
        _offsetRatio < 1 &&
        _isViewActive()) {
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
      body: Stack(
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
              child: CustomScrollView(
                scrollDirection: Axis.horizontal,
                physics: const PageScrollPhysics(),
                controller: _homeViewPageController,
                scrollCacheExtent: _startPreloading
                    ? const ScrollCacheExtent.viewport(1)
                    : null,
                slivers: [
                  SliverFillViewport(
                    delegate: SliverChildListDelegate([
                      const ChatListView(),
                      Container(),
                      const MemoriesView(),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: _offsetRatio == 0
                ? GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: _mainCameraController.onDoubleTap,
                    onTapDown: _mainCameraController.onTapDown,
                  )
                : const SizedBox.shrink(),
          ),
          Positioned(
            key: const ValueKey('camera_controls'),
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
                    ((1 - (_offsetRatio * 4) % 1) == 1) && _activePageIdx == 1,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: (_activePageIdx != 2 || _isBottomNavVisible)
            ? BottomNavigationBar(
                showSelectedLabels: false,
                showUnselectedLabels: false,
                unselectedIconTheme: IconThemeData(
                  color: Theme.of(
                    context,
                  ).colorScheme.inverseSurface.withAlpha(150),
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
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
