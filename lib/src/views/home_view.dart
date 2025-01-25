import 'package:pie_menu/pie_menu.dart';

import 'camera_preview_view.dart';
import 'chat_list_view.dart';
import 'profile_view.dart';
import '../settings/settings_controller.dart';
import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.settingsController});
  final SettingsController settingsController;

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  int _activePageIdx = 0;
  final PageController _pageController = PageController(initialPage: 0);
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
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _activePageIdx = index;
            });
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
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: ""),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: "",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: ""),
          ],
          onTap: (int index) {
            setState(() {
              _activePageIdx = index;
              _pageController.animateToPage(_activePageIdx,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.bounceIn);
            });
          },
          currentIndex: _activePageIdx,
        ),
      ),
    );
  }
}
