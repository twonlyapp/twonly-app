import 'dart:math';

import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/json_models/userdata.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/utils/storage.dart';

class AvatarCreator extends StatefulWidget {
  const AvatarCreator({super.key});

  @override
  State<AvatarCreator> createState() => _AvatarCreatorState();
}

class _AvatarCreatorState extends State<AvatarCreator> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Avatar"),
        centerTitle: true,
      ),
      body: ListView(
        physics: BouncingScrollPhysics(),
        children: <Widget>[
          SizedBox(
            height: 25,
          ),
          SizedBox(
            height: 25,
          ),
          AvatarMakerAvatar(
            backgroundColor: Colors.transparent,
            radius: 100,
          ),
          SizedBox(
            height: 25,
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
                    label: Text("Customize"),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewPage(),
                      ),
                    ),
                  ),
                ),
              ),
              Spacer(flex: 2),
            ],
          ),
          SizedBox(
            height: 100,
          ),
        ],
      ),
    );
  }
}

class NewPage extends StatelessWidget {
  const NewPage({super.key});

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
    await notifyContactsAboutAvatarChange();
  }

  @override
  Widget build(BuildContext context) {
    var _width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(),
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
