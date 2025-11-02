import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';

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
    initAsync();
    super.initState();
  }

  Future<void> initAsync() async {
    if (widget.action.contactId != null) {
      contact =
          await twonlyDB.contactsDao.getContactById(widget.action.contactId!);
    }

    if (widget.action.affectedContactId != null) {
      affectedContact = await twonlyDB.contactsDao
          .getContactById(widget.action.affectedContactId!);
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var text = '';

    final affected = (affectedContact == null)
        ? 'you'
        : "${getContactDisplayName(affectedContact!)}'s";
    final affectedR = (affectedContact == null) ? 'your' : affected;
    final maker = (contact == null) ? '' : getContactDisplayName(contact!);

    switch (widget.action.type) {
      case GroupActionType.updatedGroupName:
        text = (contact == null)
            ? 'You have changed the group name to "${widget.action.newGroupName}".'
            : '$maker has changed the group name to "${widget.action.newGroupName}".';
      case GroupActionType.createdGroup:
      case GroupActionType.removedMember:
      case GroupActionType.addMember:
      case GroupActionType.leftGroup:
        break;
      case GroupActionType.promoteToAdmin:
        text = (contact == null)
            ? 'You made $affected an admin.'
            : '$maker made $affected an admin.';
      case GroupActionType.demoteToMember:
        text = (contact == null)
            ? 'You revoked $affected admin rights.'
            : '$maker revoked $affectedR admin rights.';
    }

    if (text == '') return Container();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: FaIcon(
                  FontAwesomeIcons.pencil,
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
