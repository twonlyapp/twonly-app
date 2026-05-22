import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';

class VerificationExpansionTileComp extends StatefulWidget {
  const VerificationExpansionTileComp({
    required this.contact,
    super.key,
  });

  final Contact contact;

  @override
  State<VerificationExpansionTileComp> createState() =>
      _VerificationExpansionTileCompState();
}

class _VerificationExpansionTileCompState
    extends State<VerificationExpansionTileComp> {
  List<KeyVerification> _keyVerifications = [];
  List<(Contact, DateTime)> _transferredTrust = [];

  late StreamSubscription<List<KeyVerification>> _streamKeyVerifications;
  late StreamSubscription<List<(Contact, DateTime)>> _streamTransferredTrust;

  @override
  void initState() {
    super.initState();
    _streamKeyVerifications = twonlyDB.keyVerificationDao
        .watchContactVerification(widget.contact.userId)
        .listen((update) {
          if (!mounted) return;
          setState(() {
            _keyVerifications = update;
          });
        });
    _streamTransferredTrust = twonlyDB.keyVerificationDao
        .watchTransferredTrustVerifications(widget.contact.userId)
        .listen((update) {
          if (!mounted) return;
          setState(() {
            _transferredTrust = update;
          });
        });
  }

  @override
  void dispose() {
    _streamKeyVerifications.cancel();
    _streamTransferredTrust.cancel();
    super.dispose();
  }

  String _verificationTypeLabel(BuildContext context, VerificationType type) {
    return switch (type) {
      VerificationType.qrScanned => context.lang.verificationTypeQrScanned,
      VerificationType.secretQrToken =>
        context.lang.verificationTypeSecretQrToken(
          getContactDisplayName(widget.contact),
        ),
      VerificationType.link => context.lang.verificationTypeLink,
      VerificationType.contactSharedByVerified =>
        context.lang.verificationTypeContactSharedByVerified,
      VerificationType.migratedFromOldVersion =>
        context.lang.verificationTypeMigratedFromOldVersion,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_keyVerifications.isEmpty && _transferredTrust.isEmpty) {
      return BetterListTile(
        leading: VerificationBadgeComp(
          contact: widget.contact,
          size: 20,
        ),
        text: context.lang.contactVerifyNumberTitle,
        onTap: () async {
          await context.push(Routes.settingsHelpFaqVerifyBadge);
          if (mounted) setState(() {});
        },
      );
    }

    return ExpansionTile(
      shape: const RoundedRectangleBorder(),
      backgroundColor: context.color.surfaceContainer,
      collapsedShape: const RoundedRectangleBorder(),
      leading: Padding(
        padding: const EdgeInsetsGeometry.only(left: 12, right: 12),
        child: VerificationBadgeComp(
          contact: widget.contact,
          size: 20,
        ),
      ),
      title: Text(context.lang.userVerifiedTitle),
      children: [
        ..._keyVerifications.map(
          (kv) => ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 16),
            title: Text(_verificationTypeLabel(context, kv.type)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.yMd(
                    Localizations.localeOf(context).toString(),
                  ).format(kv.createdAt),
                  style: TextStyle(
                    color: context.color.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 8,
                  icon: Icon(
                    FontAwesomeIcons.trash,
                    size: 8,
                    color: context.color.onSurfaceVariant,
                  ),
                  onPressed: () async {
                    final confirm = await showAlertDialog(
                      context,
                      context.lang.deleteVerificationTitle,
                      context.lang.deleteVerificationBody,
                    );
                    if (confirm) {
                      await twonlyDB.keyVerificationDao
                          .deleteKeyVerificationById(
                            kv.verificationId,
                            widget.contact.userId,
                          );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        ..._transferredTrust.map(
          (tt) => ListTile(
            dense: true,
            title: Row(
              children: [
                Text(
                  context.lang.contactVerifiedBy(
                    getContactDisplayName(tt.$1),
                  ),
                ),
                VerificationBadgeComp(
                  contact: tt.$1,
                ),
              ],
            ),
            trailing: Text(
              DateFormat.yMd(
                Localizations.localeOf(context).toString(),
              ).format(tt.$2),
              style: TextStyle(
                color: context.color.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
