import 'package:flutter/material.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/qr.utils.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class VerificationFailureDialog extends StatelessWidget {
  const VerificationFailureDialog({
    required this.title,
    required this.message,
    this.contact,
    super.key,
  });

  final String title;
  final String message;
  final Contact? contact;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    Contact? contact,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => VerificationFailureDialog(
        title: title,
        message: message,
        contact: contact,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: context.color.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contact != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AvatarIcon(contactId: contact!.userId, fontSize: 16),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      getContactDisplayName(contact!),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.color.errorContainer,
              ),
              child: Icon(
                Icons.gpp_bad_outlined,
                size: 52,
                color: context.color.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: context.color.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: MyButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.lang.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showQrCodeVerificationFailure(
  BuildContext context,
  QrCodeLinkResult result,
) {
  final contact = result.contact;
  final title = contact == null
      ? switch (result.status) {
          QrCodeLinkStatus.invalid => context.lang.verificationLinkInvalidTitle,
          QrCodeLinkStatus.ownProfile =>
            context.lang.verificationOwnProfileTitle,
          _ => context.lang.verificationLinkErrorTitle,
        }
      : context.lang.couldNotVerifyUsername(getContactDisplayName(contact));

  final message = switch (result.status) {
    QrCodeLinkStatus.keyMismatch => context.lang.linkPubkeyDoesNotMatch,
    QrCodeLinkStatus.missingSession => context.lang.verificationMissingSession,
    QrCodeLinkStatus.invalid => context.lang.verificationLinkInvalid,
    QrCodeLinkStatus.ownProfile => context.lang.verificationOwnProfile,
    _ => context.lang.verificationLinkError,
  };

  return VerificationFailureDialog.show(
    context,
    title: title,
    message: message,
    contact: contact,
  );
}
