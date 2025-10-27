import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/views/chats/chat_list_components/group_list_item.dart';

class ArchivedChatsView extends StatefulWidget {
  const ArchivedChatsView({super.key});

  @override
  State<ArchivedChatsView> createState() => _ArchivedChatsViewState();
}

class _ArchivedChatsViewState extends State<ArchivedChatsView> {
  List<Group> _groupsArchived = [];
  late StreamSubscription<List<Group>> _contactsSub;

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  Future<void> initAsync() async {
    final stream = twonlyDB.groupsDao.watchGroupsForChatList();
    _contactsSub = stream.listen((groups) {
      setState(() {
        _groupsArchived = groups.where((x) => x.archived).toList();
      });
    });
  }

  @override
  void dispose() {
    _contactsSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archivierte Chats'),
      ),
      body: ListView(
        children: _groupsArchived.map((group) {
          return GroupListItem(
            group: group,
          );
        }).toList(),
      ),
    );
  }
}
