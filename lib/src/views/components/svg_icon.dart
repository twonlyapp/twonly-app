import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcons {
  static const String verifiedGreen = 'assets/icons/verified_badge_green.svg';
  static const String verifiedRed = 'assets/icons/verified_badge_red.svg';
}

class SvgIcon extends StatelessWidget {
  const SvgIcon({
    required this.assetPath,
    super.key,
    this.size = 24.0,
    this.color,
  });
  final String assetPath;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter:
          color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}
