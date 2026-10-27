import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/group_list_item.comp.dart';

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
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    final stream = watchRustDatabase(
      (control) => rust_groups.watchGroups(
        input: const db_groups.GroupQuery(
          filter: db_groups.GroupFilter.chatList,
        ),
        control: control,
      ),
    );
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
        title: Text(context.lang.archivedChats),
      ),
      body: ListView(
        children: _groupsArchived.map((group) {
          return GroupListItemComp(
            key: ValueKey(group.groupId),
            group: group,
          );
        }).toList(),
      ),
    );
  }
}
