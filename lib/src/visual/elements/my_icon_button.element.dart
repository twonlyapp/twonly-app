import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/reactive_tap_feedback.element.dart';

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
    final colors = context.color;
    final disabledBgColor = colors.surfaceContainerHighest;
    final disabledFgColor = colors.onSurface.withValues(alpha: 0.38);

    late final Color bgColor;
    late final Color fgColor;

    if (widget.variant == MyIconButtonVariant.primary) {
      bgColor = context.color.primary;
      fgColor = colors.onPrimary;
    } else {
      bgColor = colors.surfaceContainerHigh;
      fgColor = colors.onSurface;
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
