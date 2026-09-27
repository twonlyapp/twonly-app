import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/reactive_tap_feedback.element.dart';

/// A borderless pill for a row of choices. A selected chip takes the primary
/// colour, like a primary button, instead of showing a checkmark.
class MyChip extends StatelessWidget {
  const MyChip({
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
    this.tooltip,
    super.key,
  });

  final Widget label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(context);
    final background = selected
        ? context.color.primary
        : isDark
        ? Colors.grey[800]!
        : Colors.grey[200]!;
    final foreground = selected
        ? Colors.black87
        : isDark
        ? Colors.white
        : Colors.black87;
    Widget chip = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: foreground, size: 18),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: foreground,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          child: label,
        ),
      ),
    );
    if (tooltip != null) chip = Tooltip(message: tooltip, child: chip);
    return Semantics(
      button: true,
      selected: selected,
      child: ReactiveTapFeedback(
        onTap: onTap,
        onLongPress: onLongPress,
        child: chip,
      ),
    );
  }
}
