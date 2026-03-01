import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/views/components/svg_icon.dart';

class VerifiedShield extends StatefulWidget {
  const VerifiedShield({
    this.contact,
    this.group,
    super.key,
    this.size = 15,
  });
  final Group? group;
  final Contact? contact;
  final double size;

  @override
  State<VerifiedShield> createState() => _VerifiedShieldState();
}

class _VerifiedShieldState extends State<VerifiedShield> {
  bool isVerified = false;
  Contact? contact;

  StreamSubscription<List<Contact>>? stream;

  @override
  void initState() {
    if (widget.group != null) {
      stream = twonlyDB.groupsDao
          .watchGroupContact(widget.group!.groupId)
          .listen((contacts) {
        if (contacts.length == 1) {
          contact = contacts.first;
        }
        setState(() {
          isVerified = contacts.every((t) => t.verified);
        });
      });
    } else if (widget.contact != null) {
      isVerified = widget.contact!.verified;
      contact = widget.contact;
    }

    super.initState();
  }

  @override
  void dispose() {
    stream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (contact == null)
          ? null
          : () => context.push(Routes.settingsPublicProfile),
      child: Tooltip(
        message: isVerified
            ? 'You verified this contact'
            : 'You have not verifies this contact.',
        child: Padding(
          padding: const EdgeInsetsGeometry.only(top: 2),
          child: SvgIcon(
            assetPath:
                isVerified ? SvgIcons.verifiedGreen : SvgIcons.verifiedRed,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}
