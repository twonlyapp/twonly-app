import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BetterListTile extends StatelessWidget {
  const BetterListTile({
    this.text,
    this.textWidget,
    this.onTap,
    this.icon,
    this.leading,
    super.key,
    this.color,
    this.subtitle,
    this.trailing,
    this.iconSize = 20,
    this.padding,
  });
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final String? text;
  final Widget? textWidget;
  final Widget? subtitle;
  final Color? color;
  final VoidCallback? onTap;
  final double iconSize;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 50,
        child: Center(
          child: (leading != null)
              ? leading
              : FaIcon(
                  icon,
                  size: iconSize,
                  color: color,
                ),
        ),
      ),
      trailing: trailing,
      title: text != null
          ? Text(
              text!,
              style: TextStyle(color: color),
            )
          : textWidget,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}
