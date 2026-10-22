import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/flame_counter.comp.dart';

class ReduceFlamesView extends StatefulWidget {
  const ReduceFlamesView({super.key});

  @override
  State<ReduceFlamesView> createState() => _ReduceFlamesViewState();
}

class _ReduceFlamesViewState extends State<ReduceFlamesView> {
  List<Group> allGroups = [];
  List<Group> backupFlames = [];
  HashSet<String> changedGroupIds = HashSet();
  late StreamSubscription<List<Group>> groupSub;

  @override
  void initState() {
    super.initState();

    final stream = watchRustDatabase(
      (control) => rust_groups.watchGroups(
        input: const db_groups.GroupQuery(
          filter: db_groups.GroupFilter.chatList,
        ),
        control: control,
      ),
    );

    groupSub = stream.listen((update) async {
      if (backupFlames.isEmpty) {
        backupFlames = update;
      }
      setState(() {
        allGroups = update.where((g) => g.flameCounter >= 1).toList();
      });
    });
  }

  @override
  void dispose() {
    unawaited(groupSub.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reduce Flames'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 40,
              left: 10,
              top: 20,
              right: 10,
            ),
            child: Column(
              children: [
                const Text(
                  'There was a bug that caused the flames in direct messages to be replaced by group flames. Here, you can reduce the flames again. If you reduce the flames, the other person MUST do the same; otherwise, they will be resynchronized to the higher value.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () async {
                    for (final backupGroup in backupFlames) {
                      if (changedGroupIds.contains(backupGroup.groupId)) {
                        await rust_groups.updateGroup(
                          id: backupGroup.groupId,
                          patch: GroupPatch(
                            flameCounter: backupGroup.flameCounter,
                          ),
                          transaction: currentDatabaseSession(),
                        );
                      }
                    }
                  },
                  child: const Text('Undo changes'),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    restorationId: 'new_message_users_list',
                    itemCount: allGroups.length,
                    itemBuilder: (context, i) {
                      final group = allGroups[i];
                      return ListTile(
                        title: Row(
                          children: [
                            Text(group.groupName),
                            FlameCounterWidget(
                              groupId: group.groupId,
                              prefix: true,
                            ),
                          ],
                        ),
                        leading: AvatarIcon(
                          group: group,
                          fontSize: 13,
                        ),
                        trailing: OutlinedButton(
                          onPressed: () {
                            changedGroupIds.add(group.groupId);
                            rust_groups.updateGroup(
                              id: group.groupId,
                              patch: GroupPatch(
                                flameCounter: group.flameCounter - 1,
                              ),
                              transaction: currentDatabaseSession(),
                            );
                          },
                          child: const Text('-1'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
