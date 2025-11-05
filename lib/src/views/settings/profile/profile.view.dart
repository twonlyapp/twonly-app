import 'dart:async';
import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/twonly_safe/common.twonly_safe.dart';
import 'package:twonly/src/services/twonly_safe/create_backup.twonly_safe.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/better_list_title.dart';
import 'package:twonly/src/views/groups/group.view.dart';
import 'package:twonly/src/views/settings/profile/modify_avatar.view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AvatarMakerController _avatarMakerController =
      PersistentAvatarMakerController(customizedPropertyCategories: []);

  @override
  void initState() {
    super.initState();
  }

  Future<void> updateUserDisplayName(String displayName) async {
    await updateUserdata((user) {
      user
        ..displayName = displayName
        ..avatarCounter = user.avatarCounter + 1;
      return user;
    });
    await notifyContactsAboutProfileChange();
    setState(() {}); // gUser has updated
  }

  Future<void> _updateUsername(String username) async {
    final result = await apiService.changeUsername(username);
    if (result.isError) {
      if (!mounted) return;

      if (result.error == ErrorCode.UsernameAlreadyTaken) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.lang.errorUsernameAlreadyTaken),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      showNetworkIssue(context);

      return;
    }

    // as the username has changes, remove the old from the server and then upload it again.
    await removeTwonlySafeFromServer();
    unawaited(performTwonlySafeBackup(force: true));

    await updateUserdata((user) {
      user
        ..username = username
        ..avatarCounter = user.avatarCounter + 1;
      return user;
    });
    await notifyContactsAboutProfileChange();
    setState(() {}); // gUser has updated
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
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          BetterListTile(
            leading: const Padding(
              padding: EdgeInsets.only(right: 5, left: 1),
              child: FaIcon(
                FontAwesomeIcons.at,
                size: 20,
              ),
            ),
            text: context.lang.registerUsernameDecoration,
            subtitle: Text(gUser.username),
            onTap: () async {
              final username = await showDisplayNameChangeDialog(
                context,
                gUser.username,
                context.lang.registerUsernameDecoration,
                context.lang.registerUsernameDecoration,
                maxLength: 12,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(12),
                  FilteringTextInputFormatter.allow(RegExp('[a-z0-9A-Z]')),
                ],
              );
              if (context.mounted && username != null && username != '') {
                await _updateUsername(username);
              }
            },
          ),
          BetterListTile(
            icon: FontAwesomeIcons.userPen,
            text: context.lang.settingsProfileEditDisplayName,
            subtitle: Text(gUser.displayName),
            onTap: () async {
              final displayName = await showDisplayNameChangeDialog(
                context,
                gUser.displayName,
                context.lang.settingsProfileEditDisplayName,
                context.lang.settingsProfileEditDisplayNameNew,
                maxLength: 30,
              );
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
  BuildContext context,
  String currentName,
  String title,
  String hintText, {
  List<TextInputFormatter>? inputFormatters,
  int? maxLength,
}) {
  final controller = TextEditingController(text: currentName);

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hintText,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(context.lang.cancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(context.lang.ok),
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
          ),
        ],
      );
    },
  );
}
