import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/components/passwordless_recovery_info_sheet.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/components/second_factor_picker.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/components/threshold_picker.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/components/trusted_friends_card.comp.dart';
import 'package:twonly/src/visual/views/shared/select_contacts.view.dart';

class PasswordLessRecoverySetup extends StatefulWidget {
  const PasswordLessRecoverySetup({super.key});

  @override
  State<PasswordLessRecoverySetup> createState() =>
      _PasswordLessRecoverySetupState();
}

class _PasswordLessRecoverySetupState extends State<PasswordLessRecoverySetup> {
  List<Contact> _selectedContacts = [];
  SecondFactorType _secondFactor = SecondFactorType.email;
  final _pinController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  int _threshold = 2;
  bool _isModify = false;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<List<int>> _loadVerifiedContacts() async {
    final kvs = await twonlyDB.select(twonlyDB.keyVerifications).get();
    final urs = await (twonlyDB.select(
      twonlyDB.userDiscoveryUserRelations,
    )..where((u) => u.publicKeyVerifiedTimestamp.isNotNull())).get();

    return [
      ...kvs.map((row) => row.contactId),
      ...urs.map((row) => row.announcedUserId),
    ];
  }

  Future<void> initAsync() async {
    final contacts = await twonlyDB.contactsDao.getAllContacts();
    if (!mounted) return;

    final verified = await _loadVerifiedContacts();
    final config = userService.currentUser.passwordLessRecovery;

    if (config != null) {
      final selectedContacts = contacts
          .where((c) => c.recoveryIsTrustedFriend)
          .toList();

      setState(() {
        _isModify = true;
        _selectedContacts = selectedContacts;
        if (config.email != null) {
          _secondFactor = SecondFactorType.email;
          _emailController.text = config.email!;
        } else if (config.pinSeed != null) {
          _secondFactor = SecondFactorType.pin;
        } else {
          _secondFactor = SecondFactorType.none;
        }
        _threshold = max(2, (selectedContacts.length / 2).ceil());
      });
    } else {
      contacts.sortBy((c) => c.mediaSendCounter);
      final verifiedContacts = contacts
          .where(
            (c) =>
                verified.contains(c.userId) &
                c.accepted &
                !c.blocked &
                !c.accountDeleted &
                !c.deletedByUser,
          )
          .toList();
      setState(() {
        _selectedContacts = verifiedContacts.sublist(
          0,
          min(8, verifiedContacts.length),
        );
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- Threshold logic ---

  int get _minThreshold => _secondFactor == SecondFactorType.none ? 4 : 2;

  int get _validThreshold => ThresholdPicker.clampThreshold(
    value: _threshold,
    minThreshold: _minThreshold,
    contactCount: _selectedContacts.length,
  );

  int get _minSelectedFriends => _validThreshold + (kReleaseMode ? 2 : 0);

  // --- Validation ---

  bool get _canEnable {
    if (_selectedContacts.length < _minSelectedFriends) return false;
    return switch (_secondFactor) {
      SecondFactorType.none => true,
      SecondFactorType.pin => _pinController.text.length >= 4,
      SecondFactorType.email => RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(_emailController.text),
    };
  }

  // --- Actions ---

  Future<void> _selectTrustedFriends() async {
    final selectedIds = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectContactsView(
          text: SelectedContactView(
            title: 'Trusted Friends',
            submitButton: (selected, _) => 'Done ($selected)',
            submitIcon: FontAwesomeIcons.check,
          ),
          alreadySelected: _selectedContacts.map((c) => c.userId).toList(),
          isAlreadySelectedLocked: false,
          onlyVerified: true,
          sortByMediaCount: true,
        ),
      ),
    );

    if (selectedIds == null) return;

    final contacts = <Contact>[];
    for (final id in selectedIds) {
      final contact = await twonlyDB.contactsDao.getContactById(id);
      if (contact != null) contacts.add(contact);
    }
    setState(() {
      _selectedContacts = contacts;
      _threshold = _validThreshold;
    });
  }

  Future<void> _enable() async {
    setState(() => _isLoading = true);

    final secondFactorValue = switch (_secondFactor) {
      SecondFactorType.none => '',
      SecondFactorType.pin => _pinController.text,
      SecondFactorType.email => _emailController.text,
    };

    final success =
        await PasswordlessRecoveryService.enablePasswordlessRecovery(
          trustedFriendIds: _selectedContacts.map((c) => c.userId).toList(),
          secondFactorType: _secondFactor,
          secondFactorValue: secondFactorValue,
          threshold: _validThreshold,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      showSnackbar(
        context,
        context.lang.passwordlessRecoveryEnableSuccess,
        level: SnackbarLevel.success,
      );
      Navigator.pop(context);
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final needsMoreFriends = _selectedContacts.length < _minSelectedFriends;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.lang.passwordlessRecovery),
          actions: [
            IconButton(
              onPressed: () => showPasswordlessRecoveryInfoSheet(context),
              icon: const Icon(Icons.info_outline_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              Text(
                context.lang.passwordlessRecoverySubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.color.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              TrustedFriendsCard(
                selectedContacts: _selectedContacts,
                needsMoreFriends: needsMoreFriends,
                missingCount: _minSelectedFriends - _selectedContacts.length,
                onSelectFriends: _selectTrustedFriends,
                onRemoveContact: (userId) => setState(() {
                  _selectedContacts.removeWhere((c) => c.userId == userId);
                  _threshold = _validThreshold;
                }),
              ),
              const SizedBox(height: 28),

              SecondFactorPicker(
                selected: _secondFactor,
                onChanged: (type) => setState(() {
                  _secondFactor = type;
                  _threshold = _validThreshold;
                }),
                pinController: _pinController,
                emailController: _emailController,
                onInputChanged: () => setState(() {}),
              ),
              const SizedBox(height: 28),

              ThresholdPicker(
                contactCount: _selectedContacts.length,
                minThreshold: _minThreshold,
                currentThreshold: _validThreshold,
                onChanged: (value) => setState(() => _threshold = value),
              ),
              const SizedBox(height: 28),

              MyButton(
                onPressed: (_canEnable && !_isLoading) ? _enable : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black87,
                          ),
                        ),
                      )
                    else
                      const FaIcon(
                        FontAwesomeIcons.shieldHeart,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _isModify
                          ? context.lang.passwordlessRecoveryModifyBtn
                          : context.lang.passwordlessRecoveryEnableBtn,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
