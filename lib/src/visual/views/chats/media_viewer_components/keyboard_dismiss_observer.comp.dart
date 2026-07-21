import 'package:flutter/material.dart';

/// Observes keyboard dismiss via viewInsets without causing the parent to
/// rebuild on every keyboard animation frame.
class KeyboardDismissObserver extends StatefulWidget {
  const KeyboardDismissObserver({
    required this.showSendTextMessageInput,
    required this.onKeyboardDismissed,
    required this.child,
    super.key,
  });

  final bool showSendTextMessageInput;
  final VoidCallback onKeyboardDismissed;
  final Widget child;

  @override
  State<KeyboardDismissObserver> createState() =>
      _KeyboardDismissObserverState();
}

class _KeyboardDismissObserverState extends State<KeyboardDismissObserver> {
  double _maxBottomInset = 0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    if (bottomInset > _maxBottomInset) {
      _maxBottomInset = bottomInset;
    } else if (bottomInset == 0 && _maxBottomInset > 0) {
      _maxBottomInset = 0;
      if (widget.showSendTextMessageInput) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onKeyboardDismissed();
          }
        });
      }
    }
    return widget.child;
  }
}
