import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'
    show FaIcon, FontAwesomeIcons;
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/profile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/svg_icon.element.dart';
import 'package:twonly/src/visual/themes/light.dart';

const colorVerificationBadgeYellow = Color.fromARGB(255, 0, 182, 238);

class VerificationBadgeInfo extends StatelessWidget {
  const VerificationBadgeInfo({
    this.displayButtons = false,
    super.key,
  });
  final bool displayButtons;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.lang.verificationBadgeGeneralDesc,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        _buildItem(
          context,
          icon: const SvgIcon(assetPath: SvgIcons.verifiedGreen, size: 40),
          description: context.lang.verificationBadgeGreenDesc,
          boldTextColor: primaryColor,
          onTap: () => context.push(Routes.cameraQRScanner),
        ),
        if (displayButtons)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IntrinsicWidth(
                  child: MyButton(
                    variant: MyButtonVariant.primaryDense,
                    onPressed: () => context.push(Routes.cameraQRScanner),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.camera),
                        const SizedBox(width: 6),
                        Text(context.lang.scanNow),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IntrinsicWidth(
                  child: MyButton(
                    variant: MyButtonVariant.primaryDense,
                    onPressed: () => context.push(Routes.settingsPublicProfile),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.qrcode),
                        const SizedBox(width: 6),
                        Text(context.lang.openQrCode),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (userService.currentUser.securityProfile != SecurityProfile.strict ||
            userService.currentUser.isUserDiscoveryEnabled)
          _buildItem(
            context,
            icon: const SvgIcon(
              assetPath: SvgIcons.verifiedGreen,
              size: 40,
              color: colorVerificationBadgeYellow,
            ),
            description: context.lang.verificationBadgeYellowDesc,
            boldTextColor: colorVerificationBadgeYellow,
          ),
        _buildItem(
          context,
          icon: const SvgIcon(assetPath: SvgIcons.verifiedRed, size: 40),
          description: context.lang.verificationBadgeRedDesc,
          boldTextColor: const Color(0xffff0000),
        ),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required Widget icon,
    required String description,
    required Color boldTextColor,
    VoidCallback? onTap,
  }) {
    final item = Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 20),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: formattedText(
                  context,
                  description,
                  boldTextColor: boldTextColor,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: item,
      );
    }
    return item;
  }
}
