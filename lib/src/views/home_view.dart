import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:twonly/src/views/components/user_context_menu.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/views/gallery/gallery_main_view.dart';
import 'camera/camera_preview_view.dart';
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

class HomeViewState extends State<HomeView> {
  int activePageIdx = 0;
  late PageController homeViewPageController;

  @override
  void initState() {
    super.initState();
    activePageIdx = widget.initialPage;
    homeViewPageController = PageController(initialPage: widget.initialPage);
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
    initAsync();
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
  void dispose() {
    selectNotificationStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PieCanvas(
      theme: getPieCanvasTheme(context),
      child: Scaffold(
        body: PageView(
          controller: homeViewPageController,
          onPageChanged: (index) {
            activePageIdx = index;
            setState(() {});
          },
          children: [
            ChatListView(),
            CameraPreviewViewPermission(),
            GalleryMainView()
          ],
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
                icon: FaIcon(FontAwesomeIcons.solidComments), label: ""),
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
