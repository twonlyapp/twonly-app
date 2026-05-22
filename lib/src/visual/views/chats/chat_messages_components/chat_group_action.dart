import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';

class ChatGroupAction extends StatefulWidget {
  const ChatGroupAction({
    required this.action,
    super.key,
  });

  final GroupHistory action;

  @override
  State<ChatGroupAction> createState() => _ChatGroupActionState();
}

class _ChatGroupActionState extends State<ChatGroupAction> {
  Contact? contact;
  Contact? affectedContact;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    if (widget.action.contactId != null) {
      contact = await twonlyDB.contactsDao.getContactById(
        widget.action.contactId!,
      );
    }

    if (widget.action.affectedContactId != null) {
      affectedContact = await twonlyDB.contactsDao.getContactById(
        widget.action.affectedContactId!,
      );
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var text = '';
    FaIconData? icon;

    final affected = (affectedContact == null)
        ? context.lang.groupActionYou
        : getContactDisplayName(affectedContact!);
    final affectedR = (affectedContact == null)
        ? context.lang.groupActionYour
        : affected;
    final maker = (contact == null) ? '' : getContactDisplayName(contact!);

    switch (widget.action.type) {
      case GroupActionType.changeDisplayMaxTime:
        final time = formatDuration(
          context,
          (widget.action.newDeleteMessagesAfterMilliseconds ?? 0) ~/ 1000,
        );
        text = (contact == null)
            ? context.lang.youChangedDisplayMaxTime(time)
            : context.lang.changeDisplayMaxTime(time, maker);
        icon = FontAwesomeIcons.stopwatch20;
      case GroupActionType.updatedGroupName:
        text = (contact == null)
            ? context.lang.youChangedGroupName(widget.action.newGroupName!)
            : context.lang.makerChangedGroupName(
                maker,
                widget.action.newGroupName!,
              );
        icon = FontAwesomeIcons.pencil;
      case GroupActionType.createdGroup:
        icon = FontAwesomeIcons.penToSquare;
        text = (contact == null)
            ? context.lang.youCreatedGroup
            : context.lang.makerCreatedGroup(maker);
      case GroupActionType.removedMember:
        icon = FontAwesomeIcons.userMinus;
        text = (contact == null)
            ? context.lang.youRemovedMember(affected)
            : context.lang.makerRemovedMember(affected, maker);
      case GroupActionType.addMember:
        icon = FontAwesomeIcons.userPlus;
        text = (contact == null)
            ? context.lang.youAddedMember(affected)
            : context.lang.makerAddedMember(affected, maker);
      case GroupActionType.promoteToAdmin:
        icon = FontAwesomeIcons.key;
        text = (contact == null)
            ? context.lang.youMadeAdmin(affected)
            : context.lang.makerMadeAdmin(affected, maker);
      case GroupActionType.demoteToMember:
        icon = FontAwesomeIcons.key;
        text = (contact == null)
            ? context.lang.youRevokedAdminRights(affected)
            : context.lang.makerRevokedAdminRights(affectedR, maker);
      case GroupActionType.leftGroup:
        icon = FontAwesomeIcons.userMinus;
        text = (contact == null)
            ? context.lang.youLeftGroup
            : context.lang.makerLeftGroup(maker);
      case GroupActionType.updatedContactUsername:
        if (contact != null) {
          icon = FontAwesomeIcons.userPen;
          text = context.lang.makerChangedUsername(
            maker,
            widget.action.oldGroupName!,
            widget.action.newGroupName!,
          );
        }
      case GroupActionType.updatedContactDisplayName:
        if (contact != null) {
          icon = FontAwesomeIcons.userPen;
          text = context.lang.makerChangedDisplayName(
            maker,
            widget.action.oldGroupName!,
            widget.action.newGroupName!,
          );
        }
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: FaIcon(
                  icon,
                  size: 10,
                  color: Colors.grey,
                ),
              ),
              const WidgetSpan(child: SizedBox(width: 8)),
              TextSpan(
                text: text,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
