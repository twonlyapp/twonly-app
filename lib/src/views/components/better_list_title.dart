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
  });
  final IconData icon;
  final String text;
  final Widget? subtitle;
  final Color? color;
  final VoidCallback onTap;
  final double iconSize;

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
