import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BetterListTile extends StatelessWidget {
  const BetterListTile({
    required this.icon,
    required this.text,
    required this.onTap,
    super.key,
    this.color,
    this.subtitle,
    this.iconSize = 20,
    this.padding,
  });
  final IconData icon;
  final String text;
  final Widget? subtitle;
  final Color? color;
  final VoidCallback onTap;
  final double iconSize;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Padding(
        padding: (padding == null)
            ? const EdgeInsets.only(
                right: 10,
                left: 19,
              )
            : padding!,
        child: FaIcon(
          icon,
          size: iconSize,
          color: color,
        ),
      ),
      title: Text(
        text,
        style: TextStyle(color: color),
      ),
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}
