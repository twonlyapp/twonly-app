import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/key_verifications.dart'
    as rust_key_verifications;
import 'package:twonly/core/bridge/database/user_discovery.dart'
    as rust_user_discovery;
import 'package:twonly/core/bridge/wrapper/signal.dart';
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/contact_enums.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/services/notifications/native.notifications.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
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
    // Contact requests belong to no conversation, so this list is the only
    // place they can be acknowledged and taken off the app badge.
    unawaited(NativeNotificationService.clearContactRequests());
    _contactsStream =
        watchRustDatabase(
          (control) => rust_contacts.watchContacts(
            input: db_contacts.ContactQuery(
              filter: db_contacts.ContactFilter.notAccepted,
              ids: Int64List(0),
            ),
            control: control,
          ),
        ).listen(
          (update) {
            if (mounted) {
              setState(() {
                _openRequestsContacts = update;
              });
            }
          },
        );

    _newAnnouncedUsersStream =
        restartDatabaseWatch(
          () => watchRustDatabase(
            (control) => rust_user_discovery
                .watchDiscoverySuggestions(
                  onlyNew: true,
                  threshold: userService.currentUser.userDiscoveryThreshold,
                  control: control,
                )
                .map(announcedUsersWithRelations),
          ),
          userService.onUserUpdated,
        ).listen((update) {
          if (mounted) {
            setState(() {
              _newAnnouncedUsers = update;
            });
          }
        });
    _allAnnouncedUsersStream =
        restartDatabaseWatch(
          () => watchRustDatabase(
            (control) => rust_user_discovery
                .watchDiscoverySuggestions(
                  onlyNew: false,
                  threshold: userService.currentUser.userDiscoveryThreshold,
                  control: control,
                )
                .map(announcedUsersWithRelations),
          ),
          userService.onUserUpdated,
        ).listen((update) {
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
    rust_user_discovery.markDiscoveryAnnouncementsShown(
      transaction: currentDatabaseSession(),
    );
  }

  Future<void> _shareProfile() async {
    final pubKey = await RustSignal.getUserPublicKey();
    final params = ShareParams(
      text:
          'https://me.twonly.eu/${userService.currentUser.username}#${base64Url.encode(pubKey)}',
    );
    await SharePlus.instance.share(params);
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

    FrbUserData? userdata;
    try {
      userdata = await RustApi.getUserData(username: username);
    } catch (_) {
      userdata = null;
    }
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

    final added = await rust_contacts.upsertContact(
      patch: ContactPatch(
        username: username,
        userId: userdata.userId,
        requested: false,
        blocked: false,
        deletedByUser: false,
        joinedAt: userdata.joinedAt == null
            ? null
            : NullableInt(
                value: databaseNullableSeconds(
                  DateTime.fromMillisecondsSinceEpoch(
                    userdata.joinedAt! * Duration.millisecondsPerSecond,
                    isUtc: true,
                  ),
                ),
              ),
      ),
      transaction: currentDatabaseSession(),
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
        await rust_key_verifications.changeKeyVerification(
          contact: userdata.userId,
          kind: VerificationType.link.name,
          updateDiscovery: userService.currentUser.isUserDiscoveryEnabled,
          verifiedAt: clock.now().millisecondsSinceEpoch,
          callbackId: isolateCallbackId,
          transaction: currentDatabaseSession(),
        );
      }
    }

    if (added > 0) {
      await RustApi.tryRequestContactById(
        contactId: userdata.userId,
        expectedPublicKey: userdata.publicIdentityKey,
      );
    }
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
                      onPressed: () => ProfileQrCodeComp.showSheet(context),
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
