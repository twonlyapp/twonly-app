import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BetterListTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? subtitle;
  final Color? color;
  final VoidCallback onTap;
  final double iconSize;

  const BetterListTile(
      {super.key,
      required this.icon,
      required this.text,
      this.color,
      this.subtitle,
      required this.onTap,
      this.iconSize = 20});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.only(
          right: 10,
          left: 19,
        ),
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
