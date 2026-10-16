import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';

class ActionButton extends StatelessWidget {
  const ActionButton(
    this.icon, {
    required this.tooltipText,
    super.key,
    this.onPressed,
    this.color,
    this.disable = false,
  });
  final VoidCallback? onPressed;
  final dynamic icon;
  final Color? color;
  final String tooltipText;
  final bool disable;

  @override
  Widget build(BuildContext context) {
    final isFaIcon = icon is FaIconData;
    return Tooltip(
      message: tooltipText,
      child: IconButton(
        icon: isFaIcon
            ? FaIcon(
                icon as FaIconData?,
                size: 25,
                color: disable
                    ? context.appColor(AppColor.mediaForegroundMuted)
                    : color ?? context.appColor(AppColor.mediaForeground),
                shadows: [
                  Shadow(
                    color: context.appColor(AppColor.mediaScrim),
                    blurRadius: 5,
                  ),
                ],
              )
            : Icon(
                icon as IconData?,
                size: 30,
                color: disable
                    ? context.appColor(AppColor.mediaForegroundMuted)
                    : color ?? context.appColor(AppColor.mediaForeground),
                shadows: [
                  Shadow(
                    color: context.appColor(AppColor.mediaScrim),
                    blurRadius: 5,
                  ),
                ],
              ),
        onPressed: () {
          if (!disable && onPressed != null) onPressed!();
        },
      ),
    );
  }
}
