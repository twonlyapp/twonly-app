import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/svg_icon.element.dart';
import 'package:twonly/src/visual/themes/light.dart';

const colorVerificationBadgeYellow = Color.fromARGB(255, 0, 182, 238);

class VerificationBadgeInfo extends StatelessWidget {
  const VerificationBadgeInfo({super.key});

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
        ),
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
  }) {
    return Padding(
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
  }
}
