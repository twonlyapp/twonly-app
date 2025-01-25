import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/utils/api.dart';
import 'package:twonly/src/views/register_view.dart';

class SearchUsernameView extends StatefulWidget {
  const SearchUsernameView({super.key});

  @override
  State<SearchUsernameView> createState() => _SearchUsernameView();
}

class _SearchUsernameView extends State<SearchUsernameView> {
  final TextEditingController searchUserName = TextEditingController();
  bool _isLoading = false;

  Future _addNewUser(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final status = await addNewContact(searchUserName.text);

    setState(() {
      _isLoading = false;
    });

    Logger("search_user_name").warning("Replace instead of pop");

    if (context.mounted) {
      if (status) {
        // Navigator.pop(context);
      } else if (context.mounted) {
        showAlertDialog(
            context,
            AppLocalizations.of(context)!.searchUsernameNotFound,
            AppLocalizations.of(context)!
                .searchUsernameNotFoundLong(searchUserName.text));
      }
    }
    return status;
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.searchUsernameTitle),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: 20, left: 10, top: 20, right: 10),
        child: Column(
          children: [
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                    onSubmitted: (_) {
                      _addNewUser(context);
                    },
                    controller: searchUserName,
                    decoration: getInputDecoration(
                        AppLocalizations.of(context)!.searchUsernameInput))),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: Icon(Icons.qr_code),
              onPressed: () {
                showAlertDialog(context, "Coming soon",
                    "This feature is not yet implemented!");
              },
              label: Text("QR-Code scannen"),
            ),
            SizedBox(height: 30),
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 10),
              child: Text(
                "Neue Followanfragen",
                style: TextStyle(fontSize: 20),
              ),
            ),
            Expanded(
              child: ContactsListView(),
            )
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30.0),
        child: FloatingActionButton(
          onPressed: () {
            if (!_isLoading) _addNewUser(context);
          },
          child: (_isLoading)
              ? const Center(child: CircularProgressIndicator())
              : Icon(Icons.arrow_right_rounded),
        ),
      ),
    );
  }
}

class ContactsListView extends StatefulWidget {
  @override
  State<ContactsListView> createState() => _ContactsListViewState();
}

class _ContactsListViewState extends State<ContactsListView> {
  List<Contact> _allContacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future _loadContacts() async {
    List<Contact> allContacts = await DbContacts.getUsers();
    _allContacts = allContacts.where((contact) => !contact.accepted).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _allContacts.length,
      itemBuilder: (context, index) {
        final contact = _allContacts[index];

        if (!contact.requested) {
          return ListTile(
            title: Text(contact.displayName),
            subtitle: Text('Pending'),
          );
        }

        return ListTile(
          title: Text(contact.displayName),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  // Handle reject action
                  print('Rejected ${contact.displayName}');
                },
              ),
              IconButton(
                icon: Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  // Handle accept action
                  print('Accepted ${contact.displayName}');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
