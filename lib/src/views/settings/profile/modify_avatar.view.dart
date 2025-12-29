import 'dart:math';
import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

class ModifyAvatar extends StatefulWidget {
  const ModifyAvatar({super.key});

  @override
  State<ModifyAvatar> createState() => _ModifyAvatarState();
}

class _ModifyAvatarState extends State<ModifyAvatar> {
  final AvatarMakerController _avatarMakerController =
      PersistentAvatarMakerController(customizedPropertyCategories: []);

  @override
  void initState() {
    super.initState();
  }

  Future<void> updateUserAvatar(String json, String svg) async {
    await updateUserdata((user) {
      user
        ..avatarJson = json
        ..avatarSvg = svg
        ..avatarCounter = user.avatarCounter + 1;
      return user;
    });
  }

  AvatarMakerThemeData getAvatarMakerTheme(BuildContext context) {
    if (isDarkMode(context)) {
      return AvatarMakerThemeData(
        boxDecoration: const BoxDecoration(
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
        secondaryBgColor: Colors.grey[850], // Dark mode secondary background
        labelTextStyle:
            const TextStyle(color: Colors.white), // Light text for dark mode
      );
    } else {
      return AvatarMakerThemeData(
        boxDecoration: const BoxDecoration(
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
        secondaryBgColor: Colors.grey[200], // Light mode secondary background
        labelTextStyle:
            const TextStyle(color: Colors.black), // Dark text for light mode
      );
    }
  }

  Future<bool?> _showBackDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            context.lang.avatarSaveChanges,
          ),
          actions: [
            FilledButton(
              child: Text(context.lang.avatarSaveChangesStore),
              onPressed: () async {
                await storeAvatarAndExit();
              },
            ),
            TextButton(
              child: Text(context.lang.avatarSaveChangesDiscard),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> storeAvatarAndExit() async {
    await _avatarMakerController.saveAvatarSVG();
    final json = _avatarMakerController.getJsonOptionsSync();
    final svg = _avatarMakerController.getAvatarSVGSync();
    await updateUserAvatar(json, svg);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, bool? result) async {
        if (didPop) return;
        if (_avatarMakerController.getJsonOptionsSync() != gUser.avatarJson) {
          // there where changes
          final shouldPop = await _showBackDialog() ?? false;
          if (context.mounted && shouldPop) {
            Navigator.pop(context);
          }
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.lang.settingsProfileCustomizeAvatar),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.zero,
                  child: AvatarMakerAvatar(
                    radius: 130,
                    backgroundColor: Colors.transparent,
                    controller: _avatarMakerController,
                  ),
                ),
                SizedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.floppyDisk),
                        onPressed: storeAvatarAndExit,
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.shuffle),
                        onPressed:
                            _avatarMakerController.randomizedSelectedOptions,
                      ),
                      IconButton(
                        icon: const Icon(FontAwesomeIcons.rotateLeft),
                        onLongPress: () async {
                          await PersistentAvatarMakerController
                              .clearAvatarMaker();
                          await _avatarMakerController.restoreState();
                        },
                        onPressed: _avatarMakerController.restoreState,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 30),
                  child: AvatarMakerCustomizer(
                    scaffoldWidth:
                        min(600, MediaQuery.of(context).size.width * 0.85),
                    theme: getAvatarMakerTheme(context),
                    controller: _avatarMakerController,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
