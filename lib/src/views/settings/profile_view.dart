import 'dart:math';

import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/components/better_list_title.dart';
import 'package:twonly/src/json_models/userdata.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  UserData? user;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future initAsync() async {
    user = await getUser();
    setState(() {});
  }

  Future updateUserDisplayname(String displayName) async {
    UserData? user = await getUser();
    if (user == null) return null;
    user.displayName = displayName;
    if (user.avatarCounter == null) {
      user.avatarCounter = 1;
    } else {
      user.avatarCounter = user.avatarCounter! + 1;
    }
    await updateUser(user);
    await notifyContactsAboutProfileChange();
    initAsync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsProfile),
      ),
      body: ListView(
        physics: BouncingScrollPhysics(),
        children: <Widget>[
          SizedBox(
            height: 25,
          ),
          AvatarMakerAvatar(
            backgroundColor: Colors.transparent,
            radius: 80,
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Spacer(flex: 2),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 35,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.edit),
                    label: Text(context.lang.settingsProfileCustomizeAvatar),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModifyAvatar(),
                      ),
                    ),
                  ),
                ),
              ),
              Spacer(flex: 2),
            ],
          ),
          SizedBox(height: 20),
          const Divider(),
          BetterListTile(
            icon: FontAwesomeIcons.userPen,
            text: context.lang.settingsProfileEditDisplayName,
            subtitle: (user == null) ? null : Text(user!.displayName),
            onTap: () async {
              final displayName =
                  await showDisplayNameChangeDialog(context, user!.displayName);

              if (context.mounted && displayName != null && displayName != "") {
                updateUserDisplayname(displayName);
              }
            },
          ),
        ],
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    var _width = MediaQuery.of(context).size.width;
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
                width: min(600, _width * 0.85),
                child: Row(
                  children: [
                    Spacer(),
                    AvatarMakerSaveWidget(
                      onTap: () async {
                        final json =
                            await AvatarMakerController.getJsonOptions();
                        final svg = await AvatarMakerController.getAvatarSVG();
                        await updateUserAvatar(json, svg);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    AvatarMakerRandomWidget(),
                    AvatarMakerResetWidget(),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 30),
                child: AvatarMakerCustomizer(
                  scaffoldWidth: min(600, _width * 0.85),
                  autosave: false,
                  theme: AvatarMakerThemeData(
                    boxDecoration: BoxDecoration(
                      boxShadow: [BoxShadow()],
                    ),
                    unselectedTileDecoration: BoxDecoration(
                      color: const Color.fromARGB(255, 83, 83, 83),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    selectedTileDecoration: BoxDecoration(
                      color: const Color.fromARGB(255, 117, 117, 117),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    selectedIconColor: Colors.white,
                    unselectedIconColor: Colors.grey,
                    primaryBgColor: Colors.transparent,
                    secondaryBgColor: Colors.transparent,
                    labelTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> showDisplayNameChangeDialog(
    BuildContext context, String currentName) {
  final TextEditingController controller =
      TextEditingController(text: currentName);

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(context.lang.settingsProfileEditDisplayName),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
              hintText: context.lang.settingsProfileEditDisplayNameNew),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(context.lang.cancel),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          TextButton(
            child: Text(context.lang.ok),
            onPressed: () {
              Navigator.of(context)
                  .pop(controller.text); // Return the input text
            },
          ),
        ],
      );
    },
  );
}
