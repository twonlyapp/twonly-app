import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart'
    show getContactDisplayName;
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';

class HelpAFriendPasswordlessRecoveryView extends StatefulWidget {
  const HelpAFriendPasswordlessRecoveryView({
    required this.notificationId,
    required this.encryptionKey,
    super.key,
  });

  final String notificationId;
  final List<int> encryptionKey;

  @override
  State<HelpAFriendPasswordlessRecoveryView> createState() =>
      _HelpAFriendPasswordlessRecoveryViewState();
}

class _HelpAFriendPasswordlessRecoveryViewState
    extends State<HelpAFriendPasswordlessRecoveryView> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _contacts = [];
  bool _isLoading = false;
  late StreamSubscription<List<Contact>> _contactSub;

  @override
  void initState() {
    super.initState();
    _contactSub = twonlyDB.contactsDao.watchAllAcceptedContacts().listen((
      update,
    ) {
      if (mounted) {
        setState(() {
          _contacts = update;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _contactSub.cancel();
    super.dispose();
  }

  Future<void> _onContactSelected(Contact contact) async {
    if (contact.recoveryContactsSecretShare == null) {
      showSnackbar(
        context,
        context.lang.passwordlessRecoveryNoShareStored,
        level: SnackbarLevel.warning,
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return ConfirmRecoveryDialog(
          contact: contact,
          onConfirm: () => _submitShare(contact),
        );
      },
    );
  }

  Future<void> _submitShare(Contact contact) async {
    setState(() => _isLoading = true);
    final res = await PasswordlessRecoveryService.submitRecoveryShare(
      widget.notificationId,
      widget.encryptionKey,
      contact,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res) {
      showSnackbar(
        context,
        context.lang.passwordlessRecoveryShareSent,
        level: SnackbarLevel.success,
      );
      Navigator.pop(context);
    } else {
      showSnackbar(
        context,
        context.lang.passwordlessRecoveryNetworkError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(context);
    final query = _searchController.text.trim().toLowerCase();

    final filteredContacts =
        _contacts.where((c) {
          final name = getContactDisplayName(c).toLowerCase();
          final username = c.username.toLowerCase();
          return name.contains(query) || username.contains(query);
        }).toList()..sort((a, b) {
          final aHasShare = a.recoveryContactsSecretShare != null;
          final bHasShare = b.recoveryContactsSecretShare != null;
          if (aHasShare && !bHasShare) return -1;
          if (!aHasShare && bHasShare) return 1;
          return getContactDisplayName(a).compareTo(getContactDisplayName(b));
        });

    return Scaffold(
      appBar: AppBar(title: Text(context.lang.passwordlessRecoveryHelpAFriend)),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.lang.passwordlessRecoverySelectContactDesc,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    MyInput(
                      controller: _searchController,
                      hintText: context.lang.passwordlessRecoverySearchContacts,
                      prefixIcon: const Icon(Icons.search),
                      onChanged: (val) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filteredContacts.isEmpty
                          ? Center(
                              child: Text(
                                context.lang.passwordlessRecoveryNoContactsFound,
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredContacts.length,
                              itemBuilder: (context, index) {
                                final contact = filteredContacts[index];
                                final hasShare =
                                    contact.recoveryContactsSecretShare != null;
                                return Opacity(
                                  opacity: hasShare ? 1.0 : 0.5,
                                  child: ListTile(
                                    leading: AvatarIcon(
                                      contactId: contact.userId,
                                    ),
                                    title: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            getContactDisplayName(contact),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        VerificationBadgeComp(
                                          contact: contact,
                                          size: 14,
                                          clickable: false,
                                        ),
                                      ],
                                    ),
                                    subtitle: hasShare
                                        ? null
                                        : Text(
                                            context.lang.passwordlessRecoveryCantHelpHim,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                    onTap: () => _onContactSelected(contact),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class ConfirmRecoveryDialog extends StatefulWidget {
  const ConfirmRecoveryDialog({
    required this.contact,
    required this.onConfirm,
    super.key,
  });

  final Contact contact;
  final VoidCallback onConfirm;

  @override
  State<ConfirmRecoveryDialog> createState() => _ConfirmRecoveryDialogState();
}

class _ConfirmRecoveryDialogState extends State<ConfirmRecoveryDialog> {
  int _secondsRemaining = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.contact.username;
    final isEnabled = _secondsRemaining == 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        context.lang.passwordlessRecoveryDoesAskedYou(username),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.lang.passwordlessRecoveryVerifySourceDesc,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      actions: [
        MyButton(
          variant: MyButtonVariant.text,
          onPressed: () => Navigator.pop(context),
          child: Text(context.lang.passwordlessRecoveryNo),
        ),
        MyButton(
          variant: MyButtonVariant.primaryMiddle,
          onPressed: isEnabled
              ? () {
                  Navigator.pop(context);
                  widget.onConfirm();
                }
              : null,
          child: Text(
            isEnabled
                ? context.lang.passwordlessRecoveryYes
                : context.lang.passwordlessRecoveryYesWithTimer(
                    _secondsRemaining.toString(),
                  ),
          ),
        ),
      ],
    );
  }
}
