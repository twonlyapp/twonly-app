import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/mediafiles/table.dart'
    as db_mediafiles;
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/providers/routing.provider.dart';
import 'package:twonly/src/services/home_widget.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/native.notifications.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/release_notes.comp.dart';
import 'package:twonly/src/visual/components/store_review_prompt.comp.dart';
import 'package:twonly/src/visual/release_notes/release_notes_0_6_0.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/camera_preview_controller_view.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/main_camera_controller.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor.view.dart';
import 'package:twonly/src/visual/views/chats/chat_list.view.dart';
import 'package:twonly/src/visual/views/memories/memories.view.dart';
import 'package:twonly/src/visual/views/settings/backup/components/backup_reminder_sheet.comp.dart';

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

  /// [_offsetRatio] for the fades, which follow the swipe without rebuilding
  /// this view on every frame.
  final ValueNotifier<double> _offsetRatioNotifier = ValueNotifier(0);
  bool _isBottomNavVisible = true;
  Timer? _disableCameraTimer;

  /// Whether [_openEditor] has the editor open over this view.
  bool _editorOpen = false;
  bool _startPreloading = false;
  bool _startupChecksComplete = false;
  bool _releaseNotesCheckScheduled = false;
  Timer? _storeReviewTimer;

  /// Reused across rebuilds of this view, which the camera and the bottom
  /// bar trigger too; a new instance would rebuild every chat row with it.
  ChatListView? _chatListView;

  final MainCameraController _mainCameraController = MainCameraController();
  late final PageController _homeViewPageController;

  StreamSubscription<Uri>? _sharedLinkSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<int>? _homeViewPageIndexSub;
  StreamSubscription<NotificationResponse>? _selectNotificationSub;
  StreamSubscription<NativeNotificationTap>? _nativeNotificationSub;
  StreamSubscription<HomeWidgetTap>? _widgetTapSub;
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
    routerProvider.routerDelegate.addListener(_onRouteChanged);
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
    _offsetRatioNotifier.value = _offsetRatio;
    _mainCameraController.qrScanningPaused = _offsetRatio != 0;
    _homeViewPageController = PageController(initialPage: initialPage);

    _mainCameraController.setState = () {
      if (mounted) setState(() {});
    };

    _homeViewPageIndexSub = streamHomeViewPageIndex.stream.listen((index) {
      if (_homeViewPageController.hasClients) {
        _homeViewPageController.jumpToPage(index);
      }
      _applyPageOffset(index.toDouble());
      if (index != 1) {
        unawaited(_mainCameraController.closeCamera());
      }
      _scheduleReleaseNotesIfNeeded();
      _syncStoreReviewTimer();
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

    _widgetTapSub = HomeWidgetService.taps.listen((tap) {
      HomeWidgetService.consumeInitialTap();
      unawaited(_openWidgetTap(tap));
    });

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
      await _openEditor(newMediaService);
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

    unawaited(
      _initAsync().whenComplete(() {
        _startupChecksComplete = true;
        _scheduleReleaseNotesIfNeeded();
        _syncStoreReviewTimer();
      }),
    );

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

  Future<void> _openWidgetTap(HomeWidgetTap tap) async {
    try {
      final group = tap.senderId == null
          ? null
          : await rust_groups
                .listGroups(
                  input: db_groups.GroupQuery(
                    filter: db_groups.GroupFilter.directContact,
                    contactId: tap.senderId,
                  ),
                  transaction: currentDatabaseSession(),
                )
                .then((rows) => rows.isEmpty ? null : rows.single);
      if (!mounted) return;
      routerProvider.go(
        group == null ? Routes.chats : Routes.chatsMessages(group.groupId),
      );
      streamHomeViewPageIndex.add(0);
    } catch (error) {
      Log.error('Could not open the widget sender chat: $error');
    }
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
    final initialWidgetTap = HomeWidgetService.consumeInitialTap();
    if (initialWidgetTap != null) {
      await _openWidgetTap(initialWidgetTap);
      return;
    }
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

    final draftMedia = await (() async {
      final files = await rust_mediafiles.listMediaFiles(
        input: const db_mediafiles.MediaQuery(
          filter: db_mediafiles.MediaFilter.draft,
        ),
        transaction: currentDatabaseSession(),
      );
      return files.isEmpty ? null : files.single;
    })();
    if (draftMedia != null) {
      await _openEditor(MediaFileService(draftMedia));
    }
  }

  /// Opens the editor on media that did not come from the camera, such as a
  /// restored draft. The camera may already be running, started with the
  /// app, and would keep running underneath the editor for as long as it is
  /// open. It is closed, and the camera page counts as hidden until the
  /// editor is left, so nothing starts it again in the meantime; the camera
  /// page starts it itself once it shows again.
  Future<void> _openEditor(MediaFileService mediaFileService) async {
    if (!mounted) return;
    _disableCameraTimer?.cancel();
    setState(() => _editorOpen = true);
    await _mainCameraController.closeCamera();
    if (!mounted) return;
    await context.navPush(
      ShareImageEditorView(
        mediaFileService: mediaFileService,
        sharedFromGallery: true,
      ),
    );
    if (mounted) setState(() => _editorOpen = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routerProvider.routerDelegate.removeListener(_onRouteChanged);
    _onMessageOpenedAppSub?.cancel();
    _homeViewPageIndexSub?.cancel();
    _selectNotificationSub?.cancel();
    _nativeNotificationSub?.cancel();
    _widgetTapSub?.cancel();
    _disableCameraTimer?.cancel();
    _storeReviewTimer?.cancel();
    _offsetRatioNotifier.dispose();
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

  void _onRouteChanged() {
    _scheduleReleaseNotesIfNeeded();
    _syncStoreReviewTimer();
  }

  void _scheduleReleaseNotesIfNeeded() {
    if (!_startupChecksComplete ||
        _releaseNotesCheckScheduled ||
        _activePageIdx != 0) {
      return;
    }
    _releaseNotesCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _releaseNotesCheckScheduled = false;
      if (!mounted || _activePageIdx != 0 || !_isViewActive()) return;
      unawaited(_showStartupSheets());
    });
  }

  Future<void> _showStartupSheets() async {
    final releaseNotesShown = await ReleaseNotesPresenter.showIfNeeded(
      context,
      releaseNotes060(context),
    );
    // One sheet per app start is enough.
    if (releaseNotesShown) {
      BackupReminderPresenter.skipThisSession();
      StoreReviewPromptPresenter.skipThisSession();
      return;
    }
    if (!mounted) return;
    if (await BackupReminderPresenter.showIfNeeded(context)) {
      StoreReviewPromptPresenter.skipThisSession();
    }
  }

  bool get _isChatListShown =>
      _startupChecksComplete &&
      _activePageIdx == 0 &&
      _offsetFromOne == 1 &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
      _isViewActive();

  /// Runs the store review countdown only while the chat list is shown, so
  /// it restarts whenever the user swipes away, opens a chat or leaves the
  /// app.
  void _syncStoreReviewTimer() {
    if (!_isChatListShown || !StoreReviewPromptPresenter.isDue) {
      _storeReviewTimer?.cancel();
      _storeReviewTimer = null;
      return;
    }
    _storeReviewTimer ??= Timer(StoreReviewPromptPresenter.delay, () {
      _storeReviewTimer = null;
      if (!_isChatListShown) return;
      unawaited(StoreReviewPromptPresenter.showIfDue(context));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _scheduleReleaseNotesIfNeeded();
      _syncStoreReviewTimer();
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
      _syncStoreReviewTimer();
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
      _applyPageOffset(_homeViewPageController.page ?? 0);
      if (notification is ScrollEndNotification) {
        _scheduleReleaseNotesIfNeeded();
      }
      _syncStoreReviewTimer();
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

  /// What the pages show apart from the fades. Only a change here rebuilds
  /// this view during a swipe.
  Object get _layoutState => (
    _activePageIdx,
    _offsetFromOne > 0,
    _offsetFromOne == 1,
    _offsetRatio == 0,
    _offsetRatio > 0.25,
    (_offsetRatio * 4) % 1 == 0,
  );

  void _applyPageOffset(double page) {
    final before = _layoutState;
    _offsetFromOne = 1.0 - page;
    _offsetRatio = _offsetFromOne.abs();
    _offsetRatioNotifier.value = _offsetRatio;
    _mainCameraController.qrScanningPaused = _offsetRatio != 0;
    _activePageIdx = page.round();
    if (_layoutState != before) setState(() {});
  }

  ChatListView _chatList() {
    final active = _offsetFromOne > 0;
    final settled = _offsetFromOne == 1;
    final current = _chatListView;
    if (current != null &&
        current.active == active &&
        current.settled == settled) {
      return current;
    }
    return _chatListView = ChatListView(active: active, settled: settled);
  }

  @override
  Widget build(BuildContext context) {
    final chatList = _chatList();
    return Scaffold(
      body: Stack(
        children: <Widget>[
          MainCameraPreview(mainCameraController: _mainCameraController),
          // Opacity only updates its layer while the swipe moves; a changing
          // color would repaint this whole stack on every frame instead.
          Positioned.fill(
            child: ValueListenableBuilder<double>(
              valueListenable: _offsetRatioNotifier,
              builder: (context, ratio, surface) => Opacity(
                opacity: ratio.clamp(0.0, 1.0),
                child: surface,
              ),
              child: ColoredBox(color: context.color.surface),
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
                      // The emoji animations pause while the list slides.
                      TickerMode(
                        enabled: chatList.settled,
                        child: chatList,
                      ),
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
            child: ValueListenableBuilder<double>(
              valueListenable: _offsetRatioNotifier,
              builder: (context, ratio, controls) =>
                  Opacity(opacity: 1 - (ratio * 4) % 1, child: controls),
              child: CameraPreviewControllerView(
                mainController: _mainCameraController,
                isVisible:
                    ((1 - (_offsetRatio * 4) % 1) == 1) &&
                    _activePageIdx == 1 &&
                    !_editorOpen,
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
                  if (mounted) {
                    setState(() {});
                    _scheduleReleaseNotesIfNeeded();
                    _syncStoreReviewTimer();
                  }
                },
                currentIndex: _activePageIdx,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
