import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/database/key_verifications.dart'
    as rust_key_verifications;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/key_verifications/table.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
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
  bool _isVerified = false;
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
        _isVerified = _verifications.isNotEmpty || _transferredTrust.isNotEmpty;
      });
    }
  }

  Future<void> _initVerificationCheck() async {
    if (widget.group.isDirectChat) {
      final contacts = joinedGroupContacts(
        await watchRustDatabase(
          (control) => rust_groups.watchGroupContacts(
            input: db_groups.GroupMembersQuery(
              groupId: widget.group.groupId,
              orderForChats: true,
            ),
            control: control,
          ),
        ).first,
      ).map((row) => row.$1).toList(growable: false);
      if (!mounted) return;
      if (contacts.isNotEmpty) {
        _directContact = contacts.first;
        _verificationSub =
            watchRustDatabase(
              (control) => rust_key_verifications
                  .watchContactVerifications(
                    contact: _directContact!.userId,
                    control: control,
                  )
                  .map(contactVerifications),
            ).listen((verifications) {
              _verifications = verifications;
              _updateVerificationState();
            });
        _transferredTrustSub =
            watchRustDatabase(
              (control) => rust_key_verifications
                  .watchTransferredVerifications(
                    contact: _directContact!.userId,
                    control: control,
                  )
                  .map(transferredVerifications),
            ).listen((transferredTrust) {
              _transferredTrust = transferredTrust;
              _updateVerificationState();
            });
      }
    } else {
      _verificationSub =
          watchRustDatabase(
                (control) => rust_key_verifications.watchGroupsVerification(
                  group: widget.group.groupId,
                  control: control,
                ),
              )
              .map(
                (rows) => rows.isEmpty
                    ? VerificationStatus.notTrusted
                    : rows.single.status,
              )
              .listen((status) {
                if (mounted) {
                  setState(() {
                    _isVerified = status == VerificationStatus.trusted;
                  });
                }
              });
      _unverifiedCountSub =
          watchRustDatabase(
                (control) => rust_key_verifications.watchGroupsVerification(
                  group: widget.group.groupId,
                  control: control,
                ),
              )
              .map((rows) => rows.isEmpty ? 0 : rows.single.unverifiedCount)
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
