import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/svg_icon.dart';

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
            icon: const SvgIcon(assetPath: SvgIcons.verifiedYellow, size: 40),
            description: context.lang.verificationBadgeYellowDesc,
          ),
          _buildItem(
            icon: const SvgIcon(assetPath: SvgIcons.verifiedRed, size: 40),
            description: context.lang.verificationBadgeRedDesc,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({required Widget icon, required String description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
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
