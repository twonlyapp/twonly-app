import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/reactive_tap_feedback.element.dart';
import 'package:twonly/src/visual/themes/light.dart';

enum MyButtonVariant {
  primary,
  secondary,
  text,
  primaryMiddle,
  primaryDense,
  secondaryDense,
  secondaryMiddle,
  error,
}

class MyButton extends StatefulWidget {
  const MyButton({
    required this.child,
    required this.onPressed,
    this.onLongPress,
    this.variant = MyButtonVariant.primary,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final MyButtonVariant variant;

  @override
  State<MyButton> createState() => _MyButtonState();
}

class _MyButtonState extends State<MyButton> {

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

    late final ButtonStyle buttonStyle;
    switch (widget.variant) {
      case MyButtonVariant.primary:
        buttonStyle = FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black87,
          disabledBackgroundColor: disabledBgColor,
          disabledForegroundColor: disabledFgColor,
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
      case MyButtonVariant.secondary:
        buttonStyle = FilledButton.styleFrom(
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
          foregroundColor: isDark ? Colors.white : Colors.black87,
          disabledBackgroundColor: disabledBgColor,
          disabledForegroundColor: disabledFgColor,
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
      case MyButtonVariant.text:
        buttonStyle = TextButton.styleFrom(
          minimumSize: const Size(0, 50),
          foregroundColor: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.black.withValues(alpha: 0.7),
          disabledForegroundColor: disabledFgColor,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        );
      case MyButtonVariant.primaryMiddle:
        buttonStyle = FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black87,
          disabledBackgroundColor: disabledBgColor,
          disabledForegroundColor: disabledFgColor,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        );
      case MyButtonVariant.primaryDense:
        buttonStyle = FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black87,
          disabledBackgroundColor: disabledBgColor,
          disabledForegroundColor: disabledFgColor,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        );
      case MyButtonVariant.secondaryDense:
        buttonStyle = FilledButton.styleFrom(
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
          foregroundColor: isDark ? Colors.white : Colors.black87,
          disabledBackgroundColor: disabledBgColor,
          disabledForegroundColor: disabledFgColor,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        );
      case MyButtonVariant.secondaryMiddle:
        buttonStyle = FilledButton.styleFrom(
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
          foregroundColor: isDark ? Colors.white : Colors.black87,
          disabledBackgroundColor: disabledBgColor,
          disabledForegroundColor: disabledFgColor,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        );
      case MyButtonVariant.error:
        buttonStyle = FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          disabledBackgroundColor: disabledBgColor,
          disabledForegroundColor: disabledFgColor,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        );
    }

    final childButton = widget.variant == MyButtonVariant.text
        ? TextButton(
            style: buttonStyle,
            onPressed: isEnabled ? () {} : null,
            child: widget.child,
          )
        : FilledButton(
            style: buttonStyle,
            onPressed: isEnabled ? () {} : null,
            child: widget.child,
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
