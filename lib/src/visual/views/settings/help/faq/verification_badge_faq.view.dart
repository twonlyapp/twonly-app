import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/verification_badge_info.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class VerificationBadeFaqView extends StatefulWidget {
  const VerificationBadeFaqView({super.key, this.contact});

  final Contact? contact;

  @override
  State<VerificationBadeFaqView> createState() =>
      _VerificationBadeFaqViewState();
}

class _VerificationBadeFaqViewState extends State<VerificationBadeFaqView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.verificationBadgeTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(40),
        children: [
          VerificationBadgeInfo(
            displayButtons: true,
            contact: widget.contact,
          ),
          if (widget.contact != null) ...[
            const SizedBox(height: 24),
            Center(
              child: IntrinsicWidth(
                child: MyButton(
                  variant: MyButtonVariant.secondaryMiddle,
                  onPressed: () => context.push(
                    Routes.settingsHelpFaqManualVerification,
                    extra: widget.contact,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(FontAwesomeIcons.fingerprint, size: 20),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(context.lang.manualVerificationOpen),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
