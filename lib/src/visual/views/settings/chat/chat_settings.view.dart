import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';

class ChatSettingsView extends StatefulWidget {
  const ChatSettingsView({super.key});

  @override
  State<ChatSettingsView> createState() => _ChatSettingsViewState();
}

class _ChatSettingsViewState extends State<ChatSettingsView> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> setAutomaticallyMarkEqualMediaFilesAsOpened(bool value) async {
    await UserService.update((u) {
      u.automaticallyMarkEqualMediaFilesAsOpened = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsChats),
      ),
      body: StreamBuilder<void>(
        stream: userService.onUserUpdated,
        builder: (context, snapshot) {
          return ListView(
            children: [
              ListTile(
                title: Text(context.lang.settingsPreSelectedReactions),
                onTap: () => context.push(Routes.settingsChatsReactions),
              ),
              SwitchListTile(
                title: Text(
                  context
                      .lang
                      .settingsAutomaticallyMarkEqualMediaFilesAsOpenedTitle,
                ),
                subtitle: Text(
                  context
                      .lang
                      .settingsAutomaticallyMarkEqualMediaFilesAsOpenedSubtitle,
                ),
                value: userService
                    .currentUser
                    .automaticallyMarkEqualMediaFilesAsOpened,
                onChanged: setAutomaticallyMarkEqualMediaFilesAsOpened,
              ),
            ],
          );
        },
      ),
    );
  }
}
