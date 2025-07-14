import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/settings/chat/chat_reactions.view.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsChats),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(context.lang.settingsPreSelectedReactions),
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (context) {
                return const ChatReactionSelectionView();
              }));
            },
          ),
        ],
      ),
    );
  }
}
