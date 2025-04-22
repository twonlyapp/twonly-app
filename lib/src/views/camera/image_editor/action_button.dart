import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final String tooltipText;
  final bool disable;

  const ActionButton(this.icon,
      {super.key,
      this.onPressed,
      this.color,
      required this.tooltipText,
      this.disable = false});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltipText,
      child: IconButton(
        icon: FaIcon(
          icon,
          size: (icon is FontAwesomeIcons) ? 25 : 30,
          color: disable
              ? const Color.fromARGB(154, 255, 255, 255)
              : color ?? Colors.white,
          shadows: [
            Shadow(
              color: const Color.fromARGB(122, 0, 0, 0),
              blurRadius: 5.0,
            )
          ],
        ),
        onPressed: () {
          if (!disable && onPressed != null) onPressed!();
        },
      ),
    );
  }
}
