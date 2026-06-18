import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/key_verification.dao.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/visual/components/verification_badge_info.comp.dart';
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
  });
  final Group? group;
  final Contact? contact;
  final double size;

  final bool showOnlyIfVerified;
  final bool clickable;
  final bool? isVerifiedByTransferredTrust;

  @override
  State<VerificationBadgeComp> createState() => _VerificationBadgeCompState();
}

class _VerificationBadgeCompState extends State<VerificationBadgeComp> {
  bool _isVerified = false;
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
    initAsync();
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
      final members = await twonlyDB.groupsDao.getGroupContact(group!.groupId);
      if (members.isNotEmpty) {
        contact = members.first;
        group = null;
      }
    }

    if (group != null) {
      _streamAllVerified = twonlyDB.keyVerificationDao
          .watchAllGroupMembersVerified(group.groupId)
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
      _streamContactVerification = twonlyDB.keyVerificationDao
          .watchContactVerification(contact.userId)
          .listen((update) {
            if (!mounted) return;
            _keyVerifications = update;
            _updateVerificationCounts();
          });

      _streamTransferredTrust = twonlyDB.keyVerificationDao
          .watchTransferredTrustVerifications(contact.userId)
          .listen((update) {
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
                ? colorVerificationBadgeYellow
                : null,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}
