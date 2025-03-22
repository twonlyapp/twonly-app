import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/components/better_list_title.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/json_models/userdata.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/settings/account_view.dart';
import 'package:twonly/src/views/settings/appearance_view.dart';
import 'package:twonly/src/views/settings/avatar_creator.dart';
import 'package:twonly/src/views/settings/help_view.dart';
import 'package:twonly/src/views/settings/privacy_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  UserData? userData;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future initAsync() async {
    userData = await getUser();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsTitle),
      ),
      body: (userData == null)
          ? null
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return AvatarCreator();
                          }));
                          initAsync();
                        },
                        child: ContactAvatar(
                          userData: userData!,
                          fontSize: 30,
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData!.displayName,
                              style: TextStyle(fontSize: 20),
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              userData!.username,
                              style: TextStyle(
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () {},
                          icon: FaIcon(FontAwesomeIcons.qrcode),
                        ),
                      )
                    ],
                  ),
                ),
                BetterListTile(
                  icon: FontAwesomeIcons.user,
                  text: context.lang.settingsAccount,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return AccountView();
                    }));
                  },
                ),
                BetterListTile(
                  icon: FontAwesomeIcons.shieldHeart,
                  text: context.lang.settingsSubscription,
                  onTap: () {},
                ),
                const Divider(),
                BetterListTile(
                  icon: FontAwesomeIcons.sun,
                  text: context.lang.settingsAppearance,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return AppearanceView();
                    }));
                  },
                ),
                BetterListTile(
                  icon: FontAwesomeIcons.lock,
                  text: context.lang.settingsPrivacy,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return PrivacyView();
                    }));
                  },
                ),
                BetterListTile(
                  icon: FontAwesomeIcons.bell,
                  text: context.lang.settingsNotification,
                  onTap: () async {},
                ),
                const Divider(),
                BetterListTile(
                  icon: FontAwesomeIcons.circleQuestion,
                  text: context.lang.settingsHelp,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return HelpView();
                      },
                    ));
                  },
                ),
              ],
            ),
    );
  }
}
