import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/better_list_title.dart';
import 'package:twonly/src/views/components/flame.dart';
import 'package:twonly/src/views/components/max_flame_list_title.dart';
import 'package:twonly/src/views/components/select_chat_deletion_time.comp.dart';
import 'package:twonly/src/views/components/verified_shield.dart';
import 'package:twonly/src/views/groups/group.view.dart';

class ContactView extends StatefulWidget {
  const ContactView(this.userId, {super.key});

  final int userId;

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  Contact? _contact;
  List<GroupMember> _memberOfGroups = [];

  late StreamSubscription<Contact?> _contactSub;
  late StreamSubscription<List<GroupMember>> _groupMemberSub;

  @override
  void initState() {
    _contactSub = twonlyDB.contactsDao.watchContact(widget.userId).listen((
      update,
    ) {
      setState(() {
        _contact = update;
      });
    });
    _groupMemberSub = twonlyDB.groupsDao
        .watchContactGroupMember(widget.userId)
        .listen((groups) async {
          _memberOfGroups = groups;
        });
    super.initState();
  }

  @override
  void dispose() {
    _contactSub.cancel();
    _groupMemberSub.cancel();
    super.dispose();
  }

  Future<void> handleUserRemoveRequest(Contact contact) async {
    var delete = true;
    for (final groupM in _memberOfGroups) {
      final group = await twonlyDB.groupsDao.getGroup(groupM.groupId);
      if (group?.deletedContent ?? false) {
        await twonlyDB.groupsDao.deleteGroup(group!.groupId);
      } else {
        delete = false;
      }
    }
    if (!mounted) return;

    if (!delete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.lang.deleteUserErrorMessage),
          duration: const Duration(seconds: 8),
        ),
      );
      return;
    }

    final remove = await showAlertDialog(
      context,
      context.lang.contactRemoveTitle(
        getContactDisplayName(contact, maxLength: 20),
      ),
      context.lang.contactRemoveBody,
    );
    if (remove) {
      await twonlyDB.contactsDao.updateContact(
        contact.userId,
        const ContactsCompanion(
          accepted: Value(false),
          requested: Value(false),
          deletedByUser: Value(true),
        ),
      );
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  Future<void> handleUserBlockRequest(Contact contact) async {
    final block = await showAlertDialog(
      context,
      context.lang.contactBlockTitle(getContactDisplayName(contact)),
      context.lang.contactBlockBody,
    );
    if (block) {
      const update = ContactsCompanion(blocked: Value(true));
      if (context.mounted) {
        await twonlyDB.contactsDao.updateContact(contact.userId, update);
      }
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  Future<void> handleReportUser(Contact contact) async {
    final reason = await showReportDialog(context, contact);
    if (reason == null) return;
    final res = await apiService.reportUser(contact.userId, reason);
    if (!mounted) return;
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.lang.userGotReported),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      showNetworkIssue(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_contact == null) return Container();
    final contact = _contact!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: ListView(
        key: ValueKey(contact.userId),
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: AvatarIcon(contactId: contact.userId, fontSize: 30),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: VerifiedShield(
                  key: GlobalKey(),
                  contact: contact,
                ),
              ),
              Text(
                getContactDisplayName(contact, maxLength: 20),
                style: const TextStyle(fontSize: 20),
              ),
              FlameCounterWidget(
                contactId: contact.userId,
                prefix: true,
              ),
            ],
          ),
          if (getContactDisplayName(contact) != contact.username)
            Center(child: Text('(${contact.username})')),
          const SizedBox(height: 50),
          BetterListTile(
            icon: FontAwesomeIcons.solidComments,
            text: context.lang.contactViewMessage,
            onTap: () async {
              final group = await twonlyDB.groupsDao.getDirectChat(
                contact.userId,
              );
              if (group != null && context.mounted) {
                await context.push(Routes.chatsMessages(group.groupId));
              }
            },
          ),
          const Divider(),
          BetterListTile(
            icon: FontAwesomeIcons.pencil,
            text: context.lang.contactNickname,
            onTap: () async {
              final nickName = await showNicknameChangeDialog(context, contact);

              if (context.mounted && nickName != null && nickName != '') {
                final update = ContactsCompanion(nickName: Value(nickName));
                await twonlyDB.contactsDao.updateContact(
                  contact.userId,
                  update,
                );
              }
            },
          ),
          SelectChatDeletionTimeListTitle(
            groupId: getUUIDforDirectChat(widget.userId, gUser.userId),
          ),
          const Divider(),
          MaxFlameListTitle(
            contactId: widget.userId,
          ),
          if (!contact.verified)
            BetterListTile(
              leading: VerifiedShield(
                contact: contact,
                size: 20,
              ),
              text: context.lang.contactVerifyNumberTitle,
              onTap: () async {
                await context.push(Routes.settingsHelpFaqVerifyBadge);
                setState(() {});
              },
            ),
          BetterListTile(
            icon: FontAwesomeIcons.flag,
            text: context.lang.reportUser,
            onTap: () => handleReportUser(contact),
          ),
          BetterListTile(
            icon: FontAwesomeIcons.ban,
            text: context.lang.contactBlock,
            onTap: () => handleUserBlockRequest(contact),
          ),
          BetterListTile(
            icon: FontAwesomeIcons.userMinus,
            iconSize: 16,
            color: Colors.red,
            text: context.lang.contactRemove,
            onTap: () => handleUserRemoveRequest(contact),
          ),
        ],
      ),
    );
  }
}

Future<String?> showNicknameChangeDialog(
  BuildContext context,
  Contact contact,
) {
  final controller = TextEditingController(
    text: getContactDisplayName(contact),
  );

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(context.lang.contactNickname),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.lang.contactNicknameNew,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(context.lang.cancel),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          TextButton(
            child: Text(context.lang.ok),
            onPressed: () {
              Navigator.of(
                context,
              ).pop(controller.text); // Return the input text
            },
          ),
        ],
      );
    },
  );
}

Future<String?> showReportDialog(
  BuildContext context,
  Contact contact,
) {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          context.lang.reportUserTitle(getContactDisplayName(contact)),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.lang.reportUserReason),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(context.lang.cancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(context.lang.ok),
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
          ),
        ],
      );
    },
  );
}
