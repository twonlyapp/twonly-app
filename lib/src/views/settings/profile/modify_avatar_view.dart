import 'dart:math';
import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/settings_change_provider.dart';
import 'package:twonly/src/utils/misc.dart';
import "package:get/get.dart";
import 'package:twonly/src/utils/storage.dart';

class ModifyAvatar extends StatelessWidget {
  const ModifyAvatar({super.key});

  Future updateUserAvatar(String json, String svg) async {
    UserData? user = await getUser();
    if (user == null) return null;

    user.avatarJson = json;
    user.avatarSvg = svg;
    if (user.avatarCounter == null) {
      user.avatarCounter = 1;
    } else {
      user.avatarCounter = user.avatarCounter! + 1;
    }
    await updateUser(user);
    await notifyContactsAboutProfileChange();
  }

  AvatarMakerThemeData getAvatarMakerTheme(BuildContext context) {
    ThemeMode? selectedTheme =
        context.watch<SettingsChangeProvider>().themeMode;

    bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    if (selectedTheme == ThemeMode.dark ||
        (selectedTheme == ThemeMode.system && isDarkMode)) {
      return AvatarMakerThemeData(
        boxDecoration: BoxDecoration(
          boxShadow: [BoxShadow()],
        ),
        unselectedTileDecoration: BoxDecoration(
          color: const Color.fromARGB(255, 50, 50, 50), // Dark mode color
          borderRadius: BorderRadius.circular(10),
        ),
        selectedTileDecoration: BoxDecoration(
          color: const Color.fromARGB(255, 100, 100, 100), // Dark mode color
          borderRadius: BorderRadius.circular(10),
        ),
        selectedIconColor: Colors.white,
        unselectedIconColor: Colors.grey,
        primaryBgColor: Colors.black, // Dark mode background
        secondaryBgColor: Colors.grey[850]!, // Dark mode secondary background
        labelTextStyle:
            TextStyle(color: Colors.white), // Light text for dark mode
      );
    } else {
      return AvatarMakerThemeData(
        boxDecoration: BoxDecoration(
          boxShadow: [BoxShadow()],
        ),
        unselectedTileDecoration: BoxDecoration(
          color: const Color.fromARGB(255, 240, 240, 240), // Light mode color
          borderRadius: BorderRadius.circular(10),
        ),
        selectedTileDecoration: BoxDecoration(
          color: const Color.fromARGB(255, 200, 200, 200), // Light mode color
          borderRadius: BorderRadius.circular(10),
        ),
        selectedIconColor: Colors.black,
        unselectedIconColor: Colors.grey,
        primaryBgColor: Colors.white, // Light mode background
        secondaryBgColor: Colors.grey[200]!, // Light mode secondary background
        labelTextStyle:
            TextStyle(color: Colors.black), // Dark text for light mode
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsProfileCustomizeAvatar),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 00),
                child: AvatarMakerAvatar(
                  radius: 130,
                  backgroundColor: Colors.transparent,
                ),
              ),
              SizedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.floppyDisk),
                      onPressed: () async {
                        final avatarmakerController =
                            Get.find<AvatarMakerController>();
                        await avatarmakerController.saveAvatarSVG();
                        final json =
                            await AvatarMakerController.getJsonOptions();
                        final svg = await AvatarMakerController.getAvatarSVG();
                        await updateUserAvatar(json, svg);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.shuffle),
                      onPressed: () {
                        final avatarmakerController =
                            Get.find<AvatarMakerController>();
                        avatarmakerController.randomizedSelectedOptions();
                      },
                    ),
                    IconButton(
                      icon: Icon(FontAwesomeIcons.rotateLeft),
                      onPressed: () {
                        final avatarMakerController =
                            Get.find<AvatarMakerController>();
                        avatarMakerController.restoreState();
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 30),
                child: AvatarMakerCustomizer(
                  scaffoldWidth:
                      min(600, MediaQuery.of(context).size.width * 0.85),
                  autosave: false,
                  theme: getAvatarMakerTheme(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
