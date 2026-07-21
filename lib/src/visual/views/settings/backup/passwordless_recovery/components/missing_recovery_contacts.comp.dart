import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/setup.passwordless_recovery.view.dart';

class MissingRecoveryContactsComp extends StatefulWidget {
  const MissingRecoveryContactsComp({super.key});

  @override
  State<MissingRecoveryContactsComp> createState() =>
      _MissingRecoveryContactsCompState();
}

class _MissingRecoveryContactsCompState
    extends State<MissingRecoveryContactsComp> {
  bool _hasEnoughFriends = false;
  bool _loading = true;
  StreamSubscription<List<Contact>>? _contactsSub;

  @override
  void initState() {
    super.initState();
    _checkFriends();
    _contactsSub = twonlyDB.contactsDao.watchAllAcceptedContacts().listen((_) {
      _checkFriends();
    });
  }

  @override
  void dispose() {
    _contactsSub?.cancel();
    super.dispose();
  }

  Future<void> _checkFriends() async {
    final user = userService.currentUser;
    if (user.currentSetupPage != null || user.passwordLessRecovery != null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    final kvs = await twonlyDB.select(twonlyDB.keyVerifications).get();
    final urs = await (twonlyDB.select(
      twonlyDB.userDiscoveryUserRelations,
    )..where((u) => u.publicKeyVerifiedTimestamp.isNotNull())).get();

    final verified = {
      ...kvs.map((row) => row.contactId),
      ...urs.map((row) => row.announcedUserId),
    };

    final contacts = await twonlyDB.contactsDao.getAllContacts();
    var count = 0;
    for (final c in contacts) {
      if (verified.contains(c.userId) &&
          c.accepted &&
          !c.blocked &&
          !c.accountDeleted &&
          !c.deletedByUser) {
        count++;
      }
    }

    if (mounted) {
      setState(() {
        _hasEnoughFriends = count >= 4;
        _loading = false;
      });
    }
  }

  Future<void> onTap() async {
    await context.navPush(const PasswordLessRecoverySetup());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, snapshot) {
        final user = userService.currentUser;

        if (user.currentSetupPage != null ||
            user.passwordLessRecovery != null) {
          return const SizedBox.shrink();
        }

        if (_loading || !_hasEnoughFriends) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                context.color.secondaryContainer.withValues(alpha: 0.2),
                context.color.secondaryContainer.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: context.color.secondary.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: context.color.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.color.secondary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: FaIcon(
                            FontAwesomeIcons.users,
                            size: 28,
                            color: context.color.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.lang.missingRecoveryContactsCardTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: context.color.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.lang.missingRecoveryContactsCardDesc,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.color.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          MyButton(
                            onPressed: onTap,
                            variant: MyButtonVariant.primaryDense,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context
                                      .lang
                                      .missingRecoveryContactsCardAction,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
