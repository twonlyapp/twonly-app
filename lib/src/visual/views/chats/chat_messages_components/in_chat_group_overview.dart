import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/key_verification.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class InChatGroupOverview extends StatefulWidget {
  const InChatGroupOverview({
    required this.group,
    super.key,
  });

  final Group group;

  @override
  State<InChatGroupOverview> createState() => _InChatGroupOverviewState();
}

class _InChatGroupOverviewState extends State<InChatGroupOverview>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  Contact? _directContact;
  StreamSubscription<dynamic>? _verificationSub;
  StreamSubscription<List<(Contact, DateTime)>>? _transferredTrustSub;
  StreamSubscription<int>? _unverifiedCountSub;
  bool _isVerified = true;
  int _unverifiedCount = 0;
  List<(KeyVerification, Contact?)> _verifications = [];
  List<(Contact, DateTime)> _transferredTrust = [];

  @override
  void initState() {
    super.initState();
    _initVerificationCheck();
  }

  void _updateVerificationState() {
    if (mounted) {
      setState(() {
        _isVerified =
            _directContact?.verified == true ||
            _verifications.isNotEmpty ||
            _transferredTrust.isNotEmpty;
      });
    }
  }

  Future<void> _initVerificationCheck() async {
    if (widget.group.isDirectChat) {
      final contacts = await twonlyDB.groupsDao.getGroupContact(
        widget.group.groupId,
      );
      if (contacts.isNotEmpty) {
        _directContact = contacts.first;
        _verificationSub = twonlyDB.keyVerificationDao
            .watchContactVerification(_directContact!.userId)
            .listen((verifications) {
              _verifications = verifications;
              _updateVerificationState();
            });
        _transferredTrustSub = twonlyDB.keyVerificationDao
            .watchTransferredTrustVerifications(_directContact!.userId)
            .listen((transferredTrust) {
              _transferredTrust = transferredTrust;
              _updateVerificationState();
            });
      }
    } else {
      _verificationSub = twonlyDB.keyVerificationDao
          .watchAllGroupMembersVerified(widget.group.groupId)
          .listen((status) {
            if (mounted) {
              setState(() {
                _isVerified = status == VerificationStatus.trusted;
              });
            }
          });
      _unverifiedCountSub = twonlyDB.keyVerificationDao
          .watchUnverifiedGroupMembersCount(widget.group.groupId)
          .listen((count) {
            if (mounted) {
              setState(() {
                _unverifiedCount = count;
              });
            }
          });
    }
  }

  @override
  void dispose() {
    _verificationSub?.cancel();
    _transferredTrustSub?.cancel();
    _unverifiedCountSub?.cancel();
    super.dispose();
  }

  void _onVerifyPressed() {
    if (widget.group.isDirectChat && _directContact != null) {
      context.push(
        Routes.settingsHelpFaqVerifyBadge,
        extra: _directContact,
      );
    } else {
      context.push(Routes.profileGroup(widget.group.groupId));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 40),
              constraints: const BoxConstraints(maxWidth: 250),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.only(
                top: 56,
                left: 14,
                right: 14,
                bottom: 14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.group.groupName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      VerificationBadgeComp(
                        group: widget.group,
                        size: 20,
                        clickable: false,
                      ),
                    ],
                  ),
                  if (!_isVerified) ...[
                    const SizedBox(height: 5),
                    Card(
                      elevation: 0,
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 14,
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.group.isDirectChat
                                  ? context.lang.inChatContactNotVerified
                                  : context.lang.groupMembersNotVerified(
                                      _unverifiedCount,
                                    ),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            MyButton(
                              variant: MyButtonVariant.secondaryDense,
                              onPressed: _onVerifyPressed,
                              child: Text(context.lang.unverifiedWarningButton),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 0,
              child: SizedBox(
                width: 80,
                height: 80,
                child: AvatarIcon(group: widget.group, fontSize: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
