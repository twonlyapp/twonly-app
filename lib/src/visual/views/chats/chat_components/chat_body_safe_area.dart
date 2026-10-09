import 'package:flutter/material.dart';

/// Paint the picker surface under system navigation while keeping the chat
/// canvas and the reserved bottom inset stable during keyboard transitions.
class ChatBodySafeArea extends StatelessWidget {
  const ChatBodySafeArea({
    required this.showingPicker,
    required this.child,
    super.key,
  });
  final bool showingPicker;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: showingPicker
          ? theme.colorScheme.surfaceContainer
          : theme.scaffoldBackgroundColor,
      child: SafeArea(
        maintainBottomViewPadding: showingPicker,
        child: ColoredBox(color: theme.scaffoldBackgroundColor, child: child),
      ),
    );
  }
}
