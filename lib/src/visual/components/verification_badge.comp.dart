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
import 'package:twonly/src/model/contact_enums.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/svg_icon.element.dart';

class VerificationBadgeComp extends StatefulWidget {
  const VerificationBadgeComp({
    this.contact,
    this.group,
    super.key,
    this.size = 15,
    this.showOnlyIfVerified = false,
    this.isVerifiedByTransferredTrust,
    this.clickable = true,
    this.verificationStatus,
    this.useProvidedStatus = false,
  });
  final Group? group;
  final Contact? contact;
  final double size;

  final bool showOnlyIfVerified;
  final bool clickable;
  final VerificationStatus? verificationStatus;
  final bool useProvidedStatus;
  final bool? isVerifiedByTransferredTrust;

  @override
  State<VerificationBadgeComp> createState() => _VerificationBadgeCompState();
}

class _VerificationBadgeCompState extends State<VerificationBadgeComp> {
  late bool _isVerified =
      widget.contact?.verified ??
      !(widget.isVerifiedByTransferredTrust ?? false);
  bool _isSharedVerified = false;
  int _verifiedByTransferredTrustCount = 0;
  int _sharedByVerifiedCount = 0;
  int _transferredTrustBaseCount = 0;

  List<(KeyVerification, Contact?)> _keyVerifications = [];
  List<(Contact, DateTime)> _transferredTrust = [];

  StreamSubscription<VerificationStatus>? _streamAllVerified;
  StreamSubscription<List<(KeyVerification, Contact?)>>?
  _streamContactVerification;
  StreamSubscription<List<(Contact, DateTime)>>? _streamTransferredTrust;

  @override
  void initState() {
    super.initState();
    if (widget.useProvidedStatus) {
      _applyVerificationStatus(
        widget.verificationStatus ?? VerificationStatus.notTrusted,
      );
    } else {
      initAsync();
    }
  }

  @override
  void didUpdateWidget(VerificationBadgeComp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.useProvidedStatus &&
        widget.verificationStatus != oldWidget.verificationStatus) {
      _applyVerificationStatus(
        widget.verificationStatus ?? VerificationStatus.notTrusted,
      );
    }
  }

  void _applyVerificationStatus(VerificationStatus status) {
    _isVerified = status == VerificationStatus.trusted;
    _isSharedVerified = false;
    _verifiedByTransferredTrustCount =
        status == VerificationStatus.partialTrusted ? 10 : 0;
  }

  void _updateVerificationCounts() {
    setState(() {
      final sharedVerifications = _keyVerifications
          .where(
            (pair) => pair.$1.type == VerificationType.contactSharedByVerified,
          )
          .toList();

      _isVerified = _keyVerifications.any(
        (pair) => pair.$1.type != VerificationType.contactSharedByVerified,
      );
      _isSharedVerified = sharedVerifications.isNotEmpty;
      _sharedByVerifiedCount = sharedVerifications.length;

      final sharedByVerifierIds = sharedVerifications
          .where((pair) => pair.$1.verifiedBy != null)
          .map((pair) => pair.$1.verifiedBy!)
          .toSet();

      _transferredTrustBaseCount = _transferredTrust
          .where((tt) => !sharedByVerifierIds.contains(tt.$1.userId))
          .length;
      _verifiedByTransferredTrustCount =
          _sharedByVerifiedCount + _transferredTrustBaseCount;
    });
  }

  Future<void> initAsync() async {
    var group = widget.group;
    var contact = widget.contact;

    if (group?.isDirectChat == true) {
      final members = joinedGroupContacts(
        await rust_groups.getGroupContacts(
          input: db_groups.GroupMembersQuery(
            groupId: group!.groupId,
            orderForChats: true,
          ),
          transaction: currentDatabaseSession(),
        ),
      ).map((row) => row.$1).toList(growable: false);
      if (members.isNotEmpty) {
        contact = members.first;
        group = null;
      }
    }

    if (group != null) {
      final watchedGroupId = group.groupId;
      _streamAllVerified =
          watchRustDatabase(
                (control) => rust_key_verifications.watchGroupsVerification(
                  group: watchedGroupId,
                  control: control,
                ),
              )
              .map(
                (rows) => rows.isEmpty
                    ? VerificationStatus.notTrusted
                    : rows.single.status,
              )
              .listen((update) {
                if (!mounted) return;
                setState(() {
                  _isVerified = false;
                  _isSharedVerified = false;
                  _verifiedByTransferredTrustCount = 0;
                  if (update == VerificationStatus.trusted) {
                    _isVerified = true;
                  }
                  if (update == VerificationStatus.partialTrusted) {
                    _verifiedByTransferredTrustCount = 10;
                  }
                });
              });
    } else if (contact != null) {
      final watchedContactId = contact.userId;
      _streamContactVerification =
          watchRustDatabase(
            (control) => rust_key_verifications
                .watchContactVerifications(
                  contact: watchedContactId,
                  control: control,
                )
                .map(contactVerifications),
          ).listen((update) {
            if (!mounted) return;
            _keyVerifications = update;
            _updateVerificationCounts();
          });

      _streamTransferredTrust =
          watchRustDatabase(
            (control) => rust_key_verifications
                .watchTransferredVerifications(
                  contact: watchedContactId,
                  control: control,
                )
                .map(transferredVerifications),
          ).listen((update) {
            if (!mounted) return;
            _transferredTrust = update;
            _updateVerificationCounts();
          });
    } else if (widget.isVerifiedByTransferredTrust != null) {
      setState(() {
        _verifiedByTransferredTrustCount = 10;
      });
    }
  }

  @override
  void dispose() {
    _streamAllVerified?.cancel();
    _streamContactVerification?.cancel();
    _streamTransferredTrust?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVerified &&
        !_isSharedVerified &&
        _verifiedByTransferredTrustCount == 0 &&
        widget.showOnlyIfVerified) {
      return Container();
    }
    return GestureDetector(
      onTap: (!widget.clickable)
          ? null
          : () => context.push(Routes.settingsHelpFaqVerifyBadge),
      child: ColoredBox(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsetsGeometry.only(
            top: 4,
            left: 3,
            right: 3,
            bottom: 3,
          ),
          child: SvgIcon(
            assetPath: _isVerified
                ? SvgIcons.verifiedGreen
                : _verifiedByTransferredTrustCount > 0
                ? SvgIcons.verifiedNumeric(_verifiedByTransferredTrustCount)
                : SvgIcons.verifiedRed,
            color: (_verifiedByTransferredTrustCount > 0 && !_isVerified)
                ? context.appColor(AppColor.verificationPending)
                : null,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}
