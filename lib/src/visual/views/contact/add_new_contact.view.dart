import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/user_discovery.dao.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/utils.api.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/profile_qr_code.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';
import 'package:twonly/src/visual/views/contact/add_new_contact_components/friend_suggestions.comp.dart';
import 'package:twonly/src/visual/views/contact/add_new_contact_components/open_requests_list.comp.dart';

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
  String? _searchError;

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

  Future<void> _shareProfile() async {
    final pubKey = await getUserPublicKey();
    final params = ShareParams(
      text:
          'https://me.twonly.eu/${userService.currentUser.username}#${base64Url.encode(pubKey)}',
    );
    await SharePlus.instance.share(params);
  }

  void _showMyQrCode() {
    // ignore: inference_failure_on_function_invocation
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: context.color.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: double.infinity),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.color.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const ProfileQrCodeComp(),
              const SizedBox(height: 24),
              Text(
                context.lang.addContactQrSheetSubtext,
                style: TextStyle(
                  fontSize: 14,
                  color: context.color.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _contactsStream.cancel();
    _newAnnouncedUsersStream.cancel();
    _allAnnouncedUsersStream.cancel();
    super.dispose();
  }

  Future<void> _requestNewUserByUsername(String username) async {
    if (userService.currentUser.username == username) return;

    setState(() {
      _isLoading = true;
    });

    final userdata = await apiService.getUserData(username);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (userdata == null) {
      setState(() {
        _searchError = context.lang.searchUsernameNotFound;
      });
      return;
    }

    setState(() {
      _searchError = null;
    });

    final addUser = await showAlertDialog(
      context,
      context.lang.userFound(username),
      context.lang.userFoundBody(username),
    );

    if (!addUser || !mounted) return;

    final added = await twonlyDB.contactsDao.insertOnConflictUpdate(
      ContactsCompanion(
        username: Value(username),
        userId: Value(userdata.userId.toInt()),
        requested: const Value(false),
        blocked: const Value(false),
        deletedByUser: const Value(false),
      ),
    );

    if (widget.publicKey != null &&
        mounted &&
        widget.publicKey!.equals(userdata.publicIdentityKey)) {
      final markAsVerified = await showAlertDialog(
        context,
        context.lang.linkFromUsername(username),
        context.lang.linkFromUsernameLong,
        customOk: context.lang.gotLinkFromFriend,
      );
      if (markAsVerified) {
        await twonlyDB.keyVerificationDao.addKeyVerification(
          userdata.userId.toInt(),
          VerificationType.link,
        );
      }
    }

    if (added > 0) await importSignalContactAndCreateRequest(userdata);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.addFriendTitle),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: MyInput(
                controller: _usernameController,
                hintText: context.lang.searchUsernameInput,
                prefixIcon: const Icon(Icons.search, size: 20),
                errorText: _searchError,
                onChanged: (value) {
                  _usernameController.text = value.toLowerCase();
                  _usernameController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _usernameController.text.length),
                  );
                  setState(() {
                    _searchError = null;
                  });
                },
                onSubmitted: _requestNewUserByUsername,
                suffixIcon: _usernameController.text.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  context.color.surfaceContainerHighest,
                              foregroundColor: context.color.onSurface,
                              minimumSize: const Size(32, 32),
                              padding: EdgeInsets.zero,
                              shape: const CircleBorder(),
                            ),
                            iconSize: 16,
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _usernameController.clear();
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 0),
                          if (_isLoading)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    context.color.primary,
                                  ),
                                ),
                              ),
                            )
                          else
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: context.color.primary,
                                foregroundColor: context.color.onPrimary,
                                minimumSize: const Size(32, 32),
                                padding: EdgeInsets.zero,
                                shape: const CircleBorder(),
                              ),
                              iconSize: 16,
                              icon: const Icon(Icons.person_add_rounded),
                              onPressed: () => _requestNewUserByUsername(
                                _usernameController.text,
                              ),
                            ),
                          const SizedBox(width: 8),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: context.color.primary,
                            foregroundColor: context.color.onPrimary,
                            minimumSize: const Size(36, 36),
                            padding: EdgeInsets.zero,
                            shape: const CircleBorder(),
                          ),
                          iconSize: 18,
                          icon: const FaIcon(FontAwesomeIcons.camera),
                          onPressed: () => context.push(Routes.cameraQRScanner),
                          tooltip: context.lang.scanOtherProfile,
                        ),
                      ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  MyButton(
                    variant: MyButtonVariant.primaryDense,
                    onPressed: _shareProfile,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.shareNodes, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          context.lang.shareYourProfile,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MyButton(
                      variant: MyButtonVariant.secondaryDense,
                      onPressed: _showMyQrCode,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(FontAwesomeIcons.qrcode, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            context.lang.openYourOwnQRcode,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  OpenRequestsListComp(
                    contacts: _openRequestsContacts,
                    relations: _allAnnouncedUsers,
                  ),
                  FriendSuggestionsComp(_newAnnouncedUsers),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
