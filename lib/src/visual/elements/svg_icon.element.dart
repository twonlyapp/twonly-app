import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

class SvgIcons {
  static const String verifiedGreen =
      'assets/icons/verified_badge_green.svg.vec';
  static const String verifiedRed = 'assets/icons/verified_badge_red.svg.vec';

  static String verifiedNumeric(int value) {
    if (value >= 4) {
      return verifiedGreen;
    }
    return 'assets/icons/verification_badge_numeric/verified_badge_$value.svg.vec';
  }
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
    final filter = color != null
        ? ColorFilter.mode(color!, BlendMode.srcIn)
        : null;

    if (assetPath.endsWith('.vec')) {
      return SvgPicture(
        AssetBytesLoader(assetPath),
        width: size,
        height: size,
        colorFilter: filter,
      );
    }

    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: filter,
    );
  }
}
