import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';
import 'package:twonly/src/visual/elements/svg_icon.element.dart';

const colorVerificationBadgeYellow = Color.fromARGB(255, 0, 182, 238);

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
          Text(
            context.lang.verificationBadgeGeneralDesc,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildItem(
            icon: const SvgIcon(assetPath: SvgIcons.verifiedGreen, size: 40),
            description: context.lang.verificationBadgeGreenDesc,
          ),
          _buildItem(
            icon: const SvgIcon(
              assetPath: SvgIcons.verifiedGreen,
              size: 40,
              color: colorVerificationBadgeYellow,
            ),
            description: context.lang.verificationBadgeYellowDesc,
          ),
          _buildItem(
            icon: const SvgIcon(assetPath: SvgIcons.verifiedRed, size: 40),
            description: context.lang.verificationBadgeRedDesc,
          ),
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

  Widget _buildItem({required Widget icon, required String description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
