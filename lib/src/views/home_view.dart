import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_menu/pie_menu.dart';
import 'camera_preview_view.dart';
import 'chat_list_view.dart';
import 'profile_view.dart';
import '../settings/settings_controller.dart';
import 'package:flutter/material.dart';

Function(int) globalUpdateOfHomeViewPageIndex = (a) {};

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.settingsController});
  final SettingsController settingsController;

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  int activePageIdx = 0;
  final PageController homeViewPageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    globalUpdateOfHomeViewPageIndex = (index) {
      homeViewPageController.jumpToPage(index);
      setState(() {
        activePageIdx = index;
      });
    };
  }

  @override
  void dispose() {
    // disable globalCallbacks to the flutter tree
    globalUpdateOfHomeViewPageIndex = (a) {};
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PieCanvas(
      theme: PieTheme(
        brightness: Theme.of(context).brightness,
        rightClickShowsMenu: true,
        radius: 70,
        buttonTheme: PieButtonTheme(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          iconColor: Theme.of(context).colorScheme.surfaceBright,
        ),
        buttonThemeHovered: PieButtonTheme(
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconColor: Theme.of(context).colorScheme.surfaceBright,
        ),
        tooltipPadding: EdgeInsets.all(20),
        overlayColor: const Color.fromARGB(41, 0, 0, 0),

        // spacing: 0,
        tooltipTextStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Scaffold(
        body: PageView(
          controller: homeViewPageController,
          onPageChanged: (index) {
            activePageIdx = index;
          },
          children: [
            ChatListView(),
            CameraPreviewViewPermission(),
            ProfileView(settingsController: widget.settingsController)
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedIconTheme:
              IconThemeData(color: const Color.fromARGB(255, 255, 255, 255)),
          items: [
            BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.solidComments), label: ""),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.camera),
              label: "",
            ),
            BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.userShield), label: ""),
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
