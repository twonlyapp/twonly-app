import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/group_enums.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/chat_deletion_time_sheet.comp.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';
import 'package:twonly/src/visual/views/groups/group.view.dart';

class SelectChatDeletionTimeListTitle extends StatefulWidget {
  const SelectChatDeletionTimeListTitle({
    required this.groupId,
    this.disabled = false,
    super.key,
  });

  final String groupId;
  final bool disabled;

  @override
  State<SelectChatDeletionTimeListTitle> createState() =>
      _SelectChatDeletionTimeListTitleState();
}

class _SelectChatDeletionTimeListTitleState
    extends State<SelectChatDeletionTimeListTitle> {
  Group? group;

  late StreamSubscription<Group?> groupSub;
  int _selectedDeletionTime = const Duration(hours: 1).inMilliseconds;

  @override
  void initState() {
    super.initState();
    groupSub =
        watchRustDatabase(
          (control) => rust_groups.watchGroups(
            input: db_groups.GroupQuery(
              filter: db_groups.GroupFilter.id,
              groupId: widget.groupId,
            ),
            control: control,
          ),
        ).map((rows) => rows.isEmpty ? null : rows.single).listen((update) {
          if (update == null) return;
          setState(() {
            group = update;
            _selectedDeletionTime = update.deleteMessagesAfterMilliseconds;
          });
        });
  }

  @override
  void dispose() {
    groupSub.cancel();
    super.dispose();
  }

  Future<void> _showDialog() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.color.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => ChatDeletionTimeSheet(
        initialMilliseconds: _selectedDeletionTime,
      ),
    );
    if (!mounted || group == null || selected == null) return;

    if (group!.deleteMessagesAfterMilliseconds != selected) {
      if (group!.isDirectChat) {
        await rust_groups.updateGroup(
          id: group!.groupId,
          patch: GroupPatch(deleteMessagesAfterMilliseconds: selected),
          transaction: currentDatabaseSession(),
        );
        await rust_groups.insertGroupHistory(
          patch: GroupHistoryPatch(
            groupId: group!.groupId,
            type: GroupActionType.changeDisplayMaxTime.name,
            newDeleteMessagesAfterMilliseconds: NullableInt(value: selected),
          ),
          transaction: currentDatabaseSession(),
        );
        await RustApi.sendEncryptedContentToGroup(
          groupId: group!.groupId,
          content: EncryptedContent(
            groupUpdate: EncryptedContent_GroupUpdate(
              groupActionType: GroupActionType.changeDisplayMaxTime.name,
              newDeleteMessagesAfterMilliseconds: Int64(selected),
            ),
          ).writeToBuffer(),
          onlySendIfNoReceiptsAreOpen: false,
        );
      } else {
        if (!await rust_groups.updateChatDeletionTime(
          groupId: group!.groupId,
          deleteMessagesAfterMilliseconds: selected,
        )) {
          if (mounted) {
            showNetworkIssue(context);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BetterListTile(
      icon: FontAwesomeIcons.stopwatch20,
      text: context.lang.deleteChatAfter,
      trailing: Text(
        chatDeletionTimeOptions(context)
                .where((option) => option.$1 == _selectedDeletionTime)
                .firstOrNull
                ?.$2 ??
            formatChatDeletionDuration(context, _selectedDeletionTime),
      ),
      onTap: widget.disabled || group == null ? null : _showDialog,
    );
  }
}
