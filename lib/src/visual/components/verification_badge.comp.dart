import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/key_verification.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/visual/components/verification_badge_info.comp.dart';
import 'package:twonly/src/visual/elements/svg_icon.element.dart';

class VerificationBadgeComp extends StatefulWidget {
  const VerificationBadgeComp({
    this.contact,
    this.group,
    super.key,
    this.size = 15,
    this.showOnlyIfVerified = false,
    this.clickable = true,
  });
  final Group? group;
  final Contact? contact;
  final double size;

  final bool showOnlyIfVerified;
  final bool clickable;

  @override
  State<VerificationBadgeComp> createState() => _VerificationBadgeCompState();
}

class _VerificationBadgeCompState extends State<VerificationBadgeComp> {
  bool _isVerified = false;
  bool _isVerifiedByTransferredTrust = false;

  StreamSubscription<VerificationStatus>? _streamAllVerified;
  StreamSubscription<List<KeyVerification>>? _streamContactVerification;
  StreamSubscription<List<(Contact, DateTime)>>? _streamTransferredTrust;

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _streamAllVerified = twonlyDB.keyVerificationDao
          .watchAllGroupMembersVerified(widget.group!.groupId)
          .listen((update) {
            if (!mounted) return;
            setState(() {
              _isVerified = false;
              _isVerifiedByTransferredTrust = false;
              if (update == VerificationStatus.trusted) {
                _isVerified = true;
              }
              if (update == VerificationStatus.partialTrusted) {
                _isVerifiedByTransferredTrust = true;
              }
            });
          });
    } else if (widget.contact != null) {
      _streamContactVerification = twonlyDB.keyVerificationDao
          .watchContactVerification(widget.contact!.userId)
          .listen((update) {
            if (!mounted) return;
            setState(() {
              Log.info('Update: ${update.length}');
              _isVerified = update.isNotEmpty;
            });
          });

      _streamTransferredTrust = twonlyDB.keyVerificationDao
          .watchTransferredTrustVerifications(widget.contact!.userId)
          .listen((update) {
            if (!mounted) return;
            setState(() {
              _isVerifiedByTransferredTrust = update.isNotEmpty;
            });
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
        !_isVerifiedByTransferredTrust &&
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
            assetPath: (_isVerified || _isVerifiedByTransferredTrust)
                ? SvgIcons.verifiedGreen
                : SvgIcons.verifiedRed,
            color: (_isVerifiedByTransferredTrust && !_isVerified)
                ? colorVerificationBadgeYellow
                : null,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}
