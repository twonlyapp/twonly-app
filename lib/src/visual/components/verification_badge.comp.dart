import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
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

  StreamSubscription<bool>? _streamAllVerified;
  StreamSubscription<List<KeyVerification>>? _streamContactVerification;

  @override
  void initState() {
    if (widget.group != null) {
      _streamAllVerified = twonlyDB.keyVerificationDao
          .watchAllGroupMembersVerified(widget.group!.groupId)
          .listen((update) {
            setState(() {
              _isVerified = update;
            });
          });
    } else if (widget.contact != null) {
      _streamContactVerification = twonlyDB.keyVerificationDao
          .watchContactVerification(widget.contact!.userId)
          .listen((update) {
            setState(() {
              _isVerified = update.isNotEmpty;
            });
          });
    }

    super.initState();
  }

  @override
  void dispose() {
    _streamAllVerified?.cancel();
    _streamContactVerification?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVerified && widget.showOnlyIfVerified) return Container();
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
                : SvgIcons.verifiedRed,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}
