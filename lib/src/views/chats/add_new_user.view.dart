import 'dart:async';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/user_discovery.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/add_new_user_components/friend_suggestions.dart';
import 'package:twonly/src/views/chats/add_new_user_components/open_requests_list.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';

class AddNewUserView extends StatefulWidget {
  const AddNewUserView({
    this.username,
    this.publicKey,
    super.key,
  });

  final String? username;
  final Uint8List? publicKey;

  @override
  State<AddNewUserView> createState() => _SearchUsernameView();
}

class _SearchUsernameView extends State<AddNewUserView> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  bool hasRequestedUsers = false;

  List<Contact> _openRequestsContacts = [];
  late StreamSubscription<List<Contact>> _contactsStream;

  AnnouncedUsersWithRelations _newAnnouncedUsers = {};
  late StreamSubscription<AnnouncedUsersWithRelations> _newAnnouncedUsersStream;

  AnnouncedUsersWithRelations _allAnnouncedUsers = {};
  late StreamSubscription<AnnouncedUsersWithRelations> _allAnnouncedUsersStream;

  @override
  void initState() {
    super.initState();
    _contactsStream = twonlyDB.contactsDao.watchNotAcceptedContacts().listen(
      (update) {
        if (mounted) {
          setState(() {
            _openRequestsContacts = update;
          });
        }
      },
    );
    _newAnnouncedUsersStream = twonlyDB.userDiscoveryDao
        .watchNewAnnouncedUsersWithRelations()
        .listen((update) {
          if (mounted) {
            setState(() {
              _newAnnouncedUsers = update;
            });
          }
        });
    _allAnnouncedUsersStream = twonlyDB.userDiscoveryDao
        .watchAllAnnouncedUsersWithRelations()
        .listen((update) {
          if (mounted) {
            setState(() {
              _allAnnouncedUsers = update;
            });
          }
        });

    if (widget.username != null) {
      _usernameController.text = widget.username!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestNewUserByUsername(widget.username!);
      });
    }
    twonlyDB.userDiscoveryDao.markAllValidAnnouncedUsersAsShown();
  }

  @override
  void dispose() {
    _contactsStream.cancel();
    _newAnnouncedUsersStream.cancel();
    _allAnnouncedUsersStream.cancel();
    super.dispose();
  }

  Future<void> _requestNewUserByUsername(String username) async {
    if (gUser.username == username) return;

    setState(() {
      _isLoading = true;
    });

    final userdata = await apiService.getUserData(username);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (userdata == null) {
      await showAlertDialog(
        context,
        context.lang.searchUsernameNotFound,
        context.lang.searchUsernameNotFoundBody(username),
      );
      return;
    }

    final addUser = await showAlertDialog(
      context,
      context.lang.userFound(username),
      context.lang.userFoundBody,
    );

    if (!addUser || !mounted) return;

    final added = await twonlyDB.contactsDao.insertOnConflictUpdate(
      ContactsCompanion(
        username: Value(username),
        userId: Value(userdata.userId.toInt()),
        requested: const Value(false),
        blocked: const Value(false),
        deletedByUser: const Value(false),
        verified: Value(
          !(widget.publicKey == null) &&
              userdata.publicIdentityKey.equals(widget.publicKey!),
        ),
      ),
    );

    if (added > 0) await importSignalContactAndCreateRequest(userdata);
  }

  InputDecoration _getInputDecoration(String hintText) {
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
        title: Text(context.lang.addFriendTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onSubmitted: _requestNewUserByUsername,
                        onChanged: (value) {
                          _usernameController.text = value.toLowerCase();
                          _usernameController.selection =
                              TextSelection.fromPosition(
                                TextPosition(
                                  offset: _usernameController.text.length,
                                ),
                              );
                          setState(() {});
                        },
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(12),
                          FilteringTextInputFormatter.allow(
                            RegExp('[a-z0-9A-Z._]'),
                          ),
                        ],
                        controller: _usernameController,
                        decoration: _getInputDecoration(
                          context.lang.searchUsernameInput,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Expanded(
                child: ListView(
                  children: [
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push(Routes.settingsPublicProfile),
                        icon: const FaIcon(FontAwesomeIcons.qrcode),
                        label: Text(context.lang.scanQrOrShow),
                      ),
                    ),
                    OpenRequestsList(
                      contacts: _openRequestsContacts,
                      relations: _allAnnouncedUsers,
                    ),
                    FriendSuggestions(_newAnnouncedUsers),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: FloatingActionButton(
          onPressed: _isLoading || _usernameController.text.isEmpty
              ? null
              : () => _requestNewUserByUsername(_usernameController.text),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : const FaIcon(FontAwesomeIcons.magnifyingGlassPlus),
        ),
      ),
    );
  }
}
