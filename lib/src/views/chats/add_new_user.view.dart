import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/headline.dart';

class AddNewUserView extends StatefulWidget {
  const AddNewUserView({super.key});

  @override
  State<AddNewUserView> createState() => _SearchUsernameView();
}

class _SearchUsernameView extends State<AddNewUserView> {
  final TextEditingController searchUserName = TextEditingController();
  bool _isLoading = false;
  bool hasRequestedUsers = false;

  List<Contact> contacts = [];
  late StreamSubscription<List<Contact>> contactsStream;

  @override
  void initState() {
    super.initState();
    contactsStream = twonlyDB.contactsDao.watchNotAcceptedContacts().listen(
          (update) => setState(() {
            contacts = update;
          }),
        );
  }

  @override
  void dispose() {
    unawaited(contactsStream.cancel());
    super.dispose();
  }

  Future<void> _addNewUser(BuildContext context) async {
    if (gUser.username == searchUserName.text) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userdata = await apiService.getUserData(searchUserName.text);
    if (!context.mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (userdata == null) {
      await showAlertDialog(
        context,
        context.lang.searchUsernameNotFound,
        context.lang.searchUsernameNotFoundBody(searchUserName.text),
      );
      return;
    }

    final addUser = await showAlertDialog(
      context,
      context.lang.userFound,
      context.lang.userFoundBody,
    );

    if (!addUser || !context.mounted) {
      return;
    }

    final added = await twonlyDB.contactsDao.insertOnConflictUpdate(
      ContactsCompanion(
        username: Value(searchUserName.text),
        userId: Value(userdata.userId.toInt()),
        requested: const Value(false),
        blocked: const Value(false),
        deletedByUser: const Value(false),
      ),
    );

    if (added > 0) {
      if (await createNewSignalSession(userdata)) {
        // 1. Setup notifications keys with the other user
        await setupNotificationWithUsers(
          forceContact: userdata.userId.toInt(),
        );
        // 2. Then send user request
        await sendCipherText(
          userdata.userId.toInt(),
          EncryptedContent(
            contactRequest: EncryptedContent_ContactRequest(
              type: EncryptedContent_ContactRequest_Type.REQUEST,
            ),
          ),
        );
      }
    }
  }

  InputDecoration getInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: context.color.primary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.color.outline),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.searchUsernameTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  onSubmitted: (_) async {
                    await _addNewUser(context);
                  },
                  onChanged: (value) {
                    searchUserName.text = value.toLowerCase();
                    searchUserName.selection = TextSelection.fromPosition(
                      TextPosition(offset: searchUserName.text.length),
                    );
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(12),
                    FilteringTextInputFormatter.allow(RegExp('[a-z0-9A-Z]')),
                  ],
                  controller: searchUserName,
                  decoration:
                      getInputDecoration(context.lang.searchUsernameInput),
                ),
              ),
              const SizedBox(height: 20),
              if (contacts.isNotEmpty)
                HeadLineComponent(
                  context.lang.searchUsernameNewFollowerTitle,
                ),
              Expanded(
                child: ContactsListView(contacts),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: FloatingActionButton(
          onPressed: _isLoading ? null : () async => _addNewUser(context),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : const FaIcon(FontAwesomeIcons.magnifyingGlassPlus),
        ),
      ),
    );
  }
}

class ContactsListView extends StatelessWidget {
  const ContactsListView(this.contacts, {super.key});
  final List<Contact> contacts;

  List<Widget> sendRequestActions(BuildContext context, Contact contact) {
    return [
      Tooltip(
        message: context.lang.searchUserNameArchiveUserTooltip,
        child: IconButton(
          icon: const FaIcon(FontAwesomeIcons.boxArchive, size: 15),
          onPressed: () async {
            const update = ContactsCompanion(requested: Value(false));
            await twonlyDB.contactsDao.updateContact(contact.userId, update);
          },
        ),
      ),
      Text(context.lang.searchUserNamePending),
    ];
  }

  List<Widget> requestedActions(BuildContext context, Contact contact) {
    return [
      Tooltip(
        message: context.lang.searchUserNameBlockUserTooltip,
        child: IconButton(
          icon: const Icon(
            Icons.person_off_rounded,
            color: Color.fromARGB(164, 244, 67, 54),
          ),
          onPressed: () async {
            const update = ContactsCompanion(blocked: Value(true));
            await twonlyDB.contactsDao.updateContact(contact.userId, update);
          },
        ),
      ),
      Tooltip(
        message: context.lang.searchUserNameRejectUserTooltip,
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () async {
            await sendCipherText(
              contact.userId,
              EncryptedContent(
                contactRequest: EncryptedContent_ContactRequest(
                  type: EncryptedContent_ContactRequest_Type.REJECT,
                ),
              ),
            );
            await twonlyDB.contactsDao.updateContact(
              contact.userId,
              const ContactsCompanion(
                accepted: Value(false),
                requested: Value(false),
                deletedByUser: Value(true),
              ),
            );
          },
        ),
      ),
      IconButton(
        icon: const Icon(Icons.check, color: Colors.green),
        onPressed: () async {
          await twonlyDB.contactsDao.updateContact(
            contact.userId,
            const ContactsCompanion(
              accepted: Value(true),
              requested: Value(false),
            ),
          );
          await twonlyDB.groupsDao.createNewDirectChat(
            contact.userId,
            GroupsCompanion(
              groupName: Value(getContactDisplayName(contact)),
            ),
          );
          await sendCipherText(
            contact.userId,
            EncryptedContent(
              contactRequest: EncryptedContent_ContactRequest(
                type: EncryptedContent_ContactRequest_Type.ACCEPT,
              ),
            ),
          );
          await notifyContactsAboutProfileChange();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final displayName = getContactDisplayName(contact);
        return ListTile(
          title: Text(displayName),
          leading: AvatarIcon(contact: contact),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: contact.requested
                ? requestedActions(context, contact)
                : sendRequestActions(context, contact),
          ),
        );
      },
    );
  }
}
