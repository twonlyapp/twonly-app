import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
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
  int _selectedDeletionTime = 0;

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
          group = update;

          final selected = _getOptions().indexWhere(
            (t) => t.$1 == update.deleteMessagesAfterMilliseconds,
          );
          setState(() {
            _selectedDeletionTime = selected % _getOptions().length;
          });
        });
  }

  @override
  void dispose() {
    groupSub.cancel();
    super.dispose();
  }

  Future<void> _showDialog(Widget child) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6),
        // The Bottom margin is provided to align the popup above the system navigation bar.
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        // Provide a background color for the popup.
        color: context.color.surface,
        // Use a SafeArea widget to avoid system overlaps.
        child: SafeArea(top: false, child: child),
      ),
    );

    if (group == null) return;

    final selected = _getOptions()[_selectedDeletionTime].$1;

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

  List<(int, String)> _getOptions() {
    return getOptions(context);
  }

  static List<(int, String)> getOptions(BuildContext context) {
    return <(int, String)>[
      (1000 * 60 * 60, context.lang.deleteChatAfterAnHour),
      (1000 * 60 * 60 * 24, context.lang.deleteChatAfterADay),
      (1000 * 60 * 60 * 24 * 7, context.lang.deleteChatAfterAWeek),
      (1000 * 60 * 60 * 24 * 30, context.lang.deleteChatAfterAMonth),
      (1000 * 60 * 60 * 24 * 365, context.lang.deleteChatAfterAYear),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BetterListTile(
      icon: FontAwesomeIcons.stopwatch20,
      text: context.lang.deleteChatAfter,
      trailing: Text(_getOptions()[_selectedDeletionTime].$2),
      onTap: widget.disabled
          ? null
          : () => _showDialog(
              CupertinoPicker(
                magnification: 1.22,
                squeeze: 1.2,
                useMagnifier: true,
                itemExtent: 32,
                // This sets the initial item.
                scrollController: FixedExtentScrollController(
                  initialItem: _selectedDeletionTime,
                ),
                // This is called when selected item is changed.
                onSelectedItemChanged: (selectedItem) {
                  setState(() {
                    _selectedDeletionTime = selectedItem;
                  });
                },
                children: List<Widget>.generate(_getOptions().length, (index) {
                  return Center(
                    child: Text(_getOptions()[index].$2),
                  );
                }),
              ),
            ),
    );
  }
}
