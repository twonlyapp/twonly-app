import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const ActionButton(this.icon, {super.key, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: FaIcon(
        icon,
        size: 30,
        color: color ?? Colors.white,
        shadows: [
          Shadow(
            color: const Color.fromARGB(122, 0, 0, 0),
            blurRadius: 5.0,
          )
        ],
      ),
      onPressed: onPressed,
    );
  }
}
