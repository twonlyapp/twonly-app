import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/group.services.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/better_list_title.dart';
import 'package:twonly/src/views/groups/group.view.dart';

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
    groupSub = twonlyDB.groupsDao.watchGroup(widget.groupId).listen((update) {
      if (update == null) return;
      group = update;

      final selected = _getOptions().indexWhere(
        (t) => t.$1 == update.deleteMessagesAfterMilliseconds,
      );
      setState(() {
        _selectedDeletionTime = selected % _getOptions().length;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    groupSub.cancel();
    super.dispose();
  }

  Future<void> _showDialog(Widget child) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6),
        // The Bottom margin is provided to align the popup above the system navigation bar.
        margin:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        // Provide a background color for the popup.
        color: CupertinoColors.systemBackground.resolveFrom(context),
        // Use a SafeArea widget to avoid system overlaps.
        child: SafeArea(top: false, child: child),
      ),
    );

    if (group == null) return;

    final selected = _getOptions()[_selectedDeletionTime].$1;

    if (group!.deleteMessagesAfterMilliseconds != selected) {
      if (group!.isDirectChat) {
        await twonlyDB.groupsDao.updateGroup(
          group!.groupId,
          GroupsCompanion(
            deleteMessagesAfterMilliseconds: Value(selected),
          ),
        );
        await sendCipherTextToGroup(
          group!.groupId,
          EncryptedContent(
            groupUpdate: EncryptedContent_GroupUpdate(
              groupActionType: GroupActionType.changeDisplayMaxTime.name,
              newDeleteMessagesAfterMilliseconds: Int64(selected),
            ),
          ),
        );
      } else {
        if (!await updateChatDeletionTime(group!, selected)) {
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
                  onSelectedItemChanged: (int selectedItem) {
                    setState(() {
                      _selectedDeletionTime = selectedItem;
                    });
                  },
                  children:
                      List<Widget>.generate(_getOptions().length, (int index) {
                    return Center(
                      child: Text(_getOptions()[index].$2),
                    );
                  }),
                ),
              ),
    );
  }
}
