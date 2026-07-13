import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/reactive_tap_feedback.element.dart';
import 'package:twonly/src/visual/themes/light.dart';

enum MyIconButtonVariant {
  primary,
  secondary,
}

class MyIconButton extends StatefulWidget {
  const MyIconButton({
    required this.icon,
    required this.onPressed,
    this.onLongPress,
    this.variant = MyIconButtonVariant.primary,
    super.key,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final MyIconButtonVariant variant;

  @override
  State<MyIconButton> createState() => _MyIconButtonState();
}

class _MyIconButtonState extends State<MyIconButton> {

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null || widget.onLongPress != null;
    final isDark = isDarkMode(context);
    final disabledBgColor = isDark
        ? const Color(0xFF353535)
        : const Color(0xFFE0E0E0);
    final disabledFgColor = isDark
        ? const Color(0xFF757575)
        : const Color(0xFF9E9E9E);

    late final Color bgColor;
    late final Color fgColor;

    if (widget.variant == MyIconButtonVariant.primary) {
      bgColor = primaryColor;
      fgColor = Colors.black87;
    } else {
      bgColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
      fgColor = isDark ? Colors.white : Colors.black87;
    }

    final childButton = FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        disabledBackgroundColor: disabledBgColor,
        disabledForegroundColor: disabledFgColor,
        minimumSize: const Size(72, 52),
        fixedSize: const Size(72, 52),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 0,
      ),
      onPressed: isEnabled ? () {} : null,
      child: widget.icon,
    );

    return ReactiveTapFeedback(
      onTap: widget.onPressed,
      onLongPress: widget.onLongPress,
      child: AbsorbPointer(
        child: childButton,
      ),
    );
  }
}
