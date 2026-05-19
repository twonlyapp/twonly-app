import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/key_verification.dao.dart';
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
  int _verifiedByTransferredTrustCount = 0;

  StreamSubscription<VerificationStatus>? _streamAllVerified;
  StreamSubscription<List<KeyVerification>>? _streamContactVerification;
  StreamSubscription<List<(Contact, DateTime)>>? _streamTransferredTrust;

  @override
  void initState() {
    super.initState();
    initAsync();
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
            setState(() {
              _isVerified = update.isNotEmpty;
            });
          });

      _streamTransferredTrust = twonlyDB.keyVerificationDao
          .watchTransferredTrustVerifications(contact.userId)
          .listen((update) {
            if (!mounted) return;
            setState(() {
              _verifiedByTransferredTrustCount = update.length;
            });
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
