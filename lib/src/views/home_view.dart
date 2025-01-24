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
    return Scaffold(
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
    );
  }
}
