import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/better_list_title.dart';
import 'package:twonly/src/views/settings/profile/modify_avatar.view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  UserData? user;
  final AvatarMakerController _avatarMakerController =
      PersistentAvatarMakerController(customizedPropertyCategories: []);

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    user = await getUser();
    setState(() {});
  }

  Future<void> updateUserDisplayName(String displayName) async {
    await updateUserdata((user) {
      user
        ..displayName = displayName
        ..avatarCounter = user.avatarCounter + 1;
      return user;
    });

    await notifyContactsAboutProfileChange();
    await initAsync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsProfile),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          const SizedBox(height: 25),
          AvatarMakerAvatar(
            backgroundColor: Colors.transparent,
            radius: 80,
            controller: _avatarMakerController,
          ),
          const SizedBox(height: 10),
          Center(
            child: SizedBox(
              height: 35,
              child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: Text(context.lang.settingsProfileCustomizeAvatar),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ModifyAvatar(),
                      ),
                    );
                    await _avatarMakerController.performRestore();
                    setState(() {});
                  }),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          BetterListTile(
            icon: FontAwesomeIcons.userPen,
            text: context.lang.settingsProfileEditDisplayName,
            subtitle: (user == null) ? null : Text(user!.displayName),
            onTap: () async {
              final displayName =
                  await showDisplayNameChangeDialog(context, user!.displayName);
              if (context.mounted && displayName != null && displayName != '') {
                await updateUserDisplayName(displayName);
              }
            },
          ),
        ],
      ),
    );
  }
}

Future<String?> showDisplayNameChangeDialog(
    BuildContext context, String currentName) {
  final controller = TextEditingController(text: currentName);

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
