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
    if (widget.action.contactId == null) return;
    contact =
        await twonlyDB.contactsDao.getContactById(widget.action.contactId!);

    if (widget.action.affectedContactId == null) return;
    affectedContact = await twonlyDB.contactsDao
        .getContactById(widget.action.affectedContactId!);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var text = '';

    if (widget.action.type == GroupActionType.updatedGroupName) {
      if (contact == null) {
        text =
            'You have changed the group name to "${widget.action.newGroupName}".';
      } else {
        text =
            '${getContactDisplayName(contact!)} has changed the group name to "${widget.action.newGroupName}".';
      }
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
