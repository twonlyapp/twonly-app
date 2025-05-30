import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/services/notification.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/views/components/headline.dart';
import 'package:twonly/src/views/components/initialsavatar.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/settings/subscription/subscription.view.dart';

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
    initStreams();
  }

  @override
  void dispose() {
    contactsStream.cancel();
    super.dispose();
  }

  void initStreams() {
    contactsStream =
        twonlyDB.contactsDao.watchNotAcceptedContacts().listen((update) {
      setState(() {
        contacts = update;
      });
    });
  }

  Future _addNewUser(BuildContext context) async {
    final user = await getUser();
    if (user == null || user.username == searchUserName.text) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final res = await apiService.getUserData(searchUserName.text);

    if (!context.mounted) {
      return;
    }

    if (res.isSuccess) {
      final addUser = await showAlertDialog(
          context, context.lang.userFound, context.lang.userFoundBody);
      if (!addUser || !context.mounted) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      int added = await twonlyDB.contactsDao.insertContact(
        ContactsCompanion(
          username: Value(searchUserName.text),
          userId: Value(res.value.userdata.userId.toInt()),
          requested: Value(false),
        ),
      );

      if (added > 0) {
        if (await createNewSignalSession(res.value.userdata)) {
          // before notifying the other party, add
          await setupNotificationWithUsers();
          await encryptAndSendMessageAsync(
            null,
            res.value.userdata.userId.toInt(),
            MessageJson(
              kind: MessageKind.contactRequest,
              timestamp: DateTime.now(),
              content: MessageContent(),
            ),
            pushKind: PushKind.contactRequest,
          );
        }
      }
    } else {
      showAlertDialog(context, context.lang.searchUsernameNotFound,
          context.lang.searchUsernameNotFoundBody(searchUserName.text));
    }
    setState(() {
      _isLoading = false;
    });
  }

  InputDecoration getInputDecoration(hintText) {
    final primaryColor =
        Theme.of(context).colorScheme.primary; // Get the primary color
    return InputDecoration(
      hintText: hintText,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9.0),
        borderSide: BorderSide(color: primaryColor, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline, width: 1.0),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isPreview = context.read<CustomChangeProvider>().plan == "Preview";
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.searchUsernameTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 20, left: 10, top: 20, right: 10),
          child: Column(
            children: [
              if (isPreview) ...[
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    context.lang.searchUserNamePreview,
                    textAlign: TextAlign.center,
                  ),
                ),
                FilledButton.icon(
                  icon: FaIcon(FontAwesomeIcons.shieldHeart),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return SubscriptionView();
                    }));
                  },
                  label: Text(context.lang.selectSubscription),
                ),
                SizedBox(height: 30),
              ],
              if (!isPreview) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    onSubmitted: (_) {
                      _addNewUser(context);
                    },
                    onChanged: (value) {
                      searchUserName.text = value.toLowerCase();
                      searchUserName.selection = TextSelection.fromPosition(
                        TextPosition(offset: searchUserName.text.length),
                      );
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(12),
                      FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9A-Z]')),
                    ],
                    controller: searchUserName,
                    decoration:
                        getInputDecoration(context.lang.searchUsernameInput),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (contacts.isNotEmpty)
                HeadLineComponent(
                  context.lang.searchUsernameNewFollowerTitle,
                ),
              Expanded(
                child: ContactsListView(contacts),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: (isPreview)
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: FloatingActionButton(
                foregroundColor: Colors.white,
                onPressed: () {
                  if (!_isLoading) _addNewUser(context);
                },
                child: (_isLoading)
                    ? const Center(child: CircularProgressIndicator())
                    : FaIcon(FontAwesomeIcons.magnifyingGlassPlus),
              ),
            ),
    );
  }
}

class ContactsListView extends StatefulWidget {
  const ContactsListView(this.contacts, {super.key});

  final List<Contact> contacts;

  @override
  State<ContactsListView> createState() => _ContactsListViewState();
}

class _ContactsListViewState extends State<ContactsListView> {
  List<Widget> sendRequestActions(Contact contact) {
    return [
      Tooltip(
        message: context.lang.searchUserNameArchiveUserTooltip,
        child: IconButton(
          icon: FaIcon(FontAwesomeIcons.boxArchive, size: 15),
          onPressed: () async {
            final update = ContactsCompanion(archived: Value(true));
            await twonlyDB.contactsDao.updateContact(contact.userId, update);
          },
        ),
      ),
      Text(context.lang.searchUserNamePending),
    ];
  }

  List<Widget> requestedActions(Contact contact) {
    return [
      Tooltip(
        message: context.lang.searchUserNameBlockUserTooltip,
        child: IconButton(
          icon: Icon(Icons.person_off_rounded,
              color: const Color.fromARGB(164, 244, 67, 54)),
          onPressed: () async {
            final update = ContactsCompanion(blocked: Value(true));
            await twonlyDB.contactsDao.updateContact(contact.userId, update);
          },
        ),
      ),
      Tooltip(
        message: context.lang.searchUserNameRejectUserTooltip,
        child: IconButton(
          icon: Icon(Icons.close, color: Colors.red),
          onPressed: () async {
            await twonlyDB.contactsDao.deleteContactByUserId(contact.userId);
            await encryptAndSendMessageAsync(
              null,
              contact.userId,
              MessageJson(
                kind: MessageKind.rejectRequest,
                timestamp: DateTime.now(),
                content: MessageContent(),
              ),
            );
          },
        ),
      ),
      IconButton(
        icon: Icon(Icons.check, color: Colors.green),
        onPressed: () async {
          final update = ContactsCompanion(accepted: Value(true));
          await twonlyDB.contactsDao.updateContact(contact.userId, update);
          await encryptAndSendMessageAsync(
            null,
            contact.userId,
            MessageJson(
              kind: MessageKind.acceptRequest,
              timestamp: DateTime.now(),
              content: MessageContent(),
            ),
            pushKind: PushKind.acceptRequest,
          );
          notifyContactsAboutProfileChange();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.contacts.length,
      itemBuilder: (context, index) {
        final contact = widget.contacts[index];
        final displayName = getContactDisplayName(contact);
        return ListTile(
          title: Text(displayName),
          leading: ContactAvatar(contact: contact),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: contact.requested
                ? requestedActions(contact)
                : sendRequestActions(contact),
          ),
        );
      },
    );
  }
}
