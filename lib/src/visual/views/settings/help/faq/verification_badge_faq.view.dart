import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/verification_badge_info.comp.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';

class VerificationBadeFaqView extends StatefulWidget {
  const VerificationBadeFaqView({super.key});

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
          const VerificationBadgeInfo(),
          const SizedBox(height: 20),
          BetterListTile(
            leading: const FaIcon(FontAwesomeIcons.camera),
            text: context.lang.scanOtherProfile,
            onTap: () => context.push(Routes.cameraQRScanner),
          ),
          BetterListTile(
            leading: const FaIcon(FontAwesomeIcons.qrcode),
            text: context.lang.openYourOwnQRcode,
            onTap: () => context.push(Routes.settingsPublicProfile),
          ),
        ],
      ),
    );
  }
}
