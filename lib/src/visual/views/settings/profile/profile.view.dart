import 'dart:async';

import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/services/backup/common.backup.dart';
import 'package:twonly/src/services/backup/create.backup.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';
import 'package:twonly/src/visual/views/groups/group.view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AvatarMakerController _avatarMakerController =
      PersistentAvatarMakerController(customizedPropertyCategories: []);

  int twonlyScore = 0;
  late StreamSubscription<int> twonlyScoreSub;

  @override
  void initState() {
    twonlyScoreSub = twonlyDB.groupsDao.watchSumTotalMediaCounter().listen((
      update,
    ) {
      setState(() {
        twonlyScore = update;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    twonlyScoreSub.cancel();
    super.dispose();
  }

  Future<void> updateUserDisplayName(String displayName) async {
    await updateUser(
      (u) => u
        ..displayName = displayName
        ..avatarCounter = u.avatarCounter + 1,
    );
  }

  Future<void> _updateUsername(String username) async {
    var filteredUsername = username.replaceAll(
      RegExp('[^a-zA-Z0-9._]'),
      '',
    );

    if (filteredUsername.length > 12) {
      filteredUsername = filteredUsername.substring(0, 12);
    }

    final result = await apiService.changeUsername(filteredUsername);
    if (result.isError) {
      if (!mounted) return;

      if (result.error == ErrorCode.UsernameAlreadyTaken ||
          result.error == ErrorCode.UsernameNotValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.error == ErrorCode.UsernameAlreadyTaken
                  ? context.lang.errorUsernameAlreadyTaken
                  : context.lang.errorUsernameNotValid,
            ),
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

    await updateUser(
      (u) => u
        ..username = username
        ..avatarCounter = u.avatarCounter + 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsProfile),
      ),
      body: StreamBuilder<void>(
        stream: userService.onUserUpdated,
        builder: (context, _) {
          return ListView(
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
                      await context.push(Routes.settingsProfileModifyAvatar);
                      await _avatarMakerController.performRestore();
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
                    FontAwesomeIcons.qrcode,
                    size: 20,
                  ),
                ),
                onTap: () => context.push(Routes.settingsPublicProfile),
                text: context.lang.profileYourQrCode,
              ),
              BetterListTile(
                leading: const Padding(
                  padding: EdgeInsets.only(right: 5, left: 1),
                  child: FaIcon(
                    FontAwesomeIcons.at,
                    size: 20,
                  ),
                ),
                text: context.lang.registerUsernameDecoration,
                subtitle: Text(userService.currentUser.username),
                onTap: () async {
                  final username = await showDisplayNameChangeDialog(
                    context,
                    userService.currentUser.username,
                    context.lang.registerUsernameDecoration,
                    context.lang.registerUsernameDecoration,
                    maxLength: 12,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(12),
                      FilteringTextInputFormatter.allow(
                        RegExp('[a-z0-9A-Z._]'),
                      ),
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
                subtitle: Text(userService.currentUser.displayName),
                onTap: () async {
                  final displayName = await showDisplayNameChangeDialog(
                    context,
                    userService.currentUser.displayName,
                    context.lang.settingsProfileEditDisplayName,
                    context.lang.settingsProfileEditDisplayNameNew,
                    maxLength: 30,
                  );
                  if (context.mounted &&
                      displayName != null &&
                      displayName != '') {
                    await updateUserDisplayName(displayName);
                  }
                },
              ),
              BetterListTile(
                text: context.lang.yourTwonlyScore,
                icon: FontAwesomeIcons.trophy,
                trailing: Text(
                  twonlyScore.toString(),
                  style: TextStyle(
                    color: context.color.primary,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          );
        },
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
    builder: (context) {
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
