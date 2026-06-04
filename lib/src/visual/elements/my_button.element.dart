import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/themes/light.dart';

enum MyButtonVariant {
  primary,
  secondary,
  text,
  primaryDense,
  secondaryDense,
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

class _MyButtonState extends State<MyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          lowerBound: double.negativeInfinity,
          upperBound: double.infinity,
          value: 0,
        )..addListener(() {
          setState(() {});
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null || widget.onLongPress != null) {
      _controller.animateTo(
        1,
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null || widget.onLongPress != null) {
      _bounce();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null || widget.onLongPress != null) {
      _bounce();
    }
  }

  void _bounce() {
    const spring = SpringDescription(
      mass: 1,
      stiffness: 400,
      damping: 15,
    );
    final simulation = SpringSimulation(
      spring,
      _controller.value,
      0,
      _controller.velocity,
    );
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    // 0 (unpressed) -> scale 1.0
    // 1 (pressed) -> scale 0.98 (subtle bounce)
    final scale = 1.0 - (_controller.value * 0.02);
    final isEnabled = widget.onPressed != null || widget.onLongPress != null;
    final isDark = isDarkMode(context);

    late final ButtonStyle buttonStyle;
    switch (widget.variant) {
      case MyButtonVariant.primary:
        buttonStyle = FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black87,
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
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        );
      case MyButtonVariant.primaryDense:
        buttonStyle = FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black87,
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: isEnabled ? _onTapDown : null,
      onTapUp: isEnabled ? _onTapUp : null,
      onTapCancel: isEnabled ? _onTapCancel : null,
      onTap: widget.onPressed,
      onLongPress: widget.onLongPress,
      child: Transform.scale(
        scale: scale,
        child: AbsorbPointer(
          child: childButton,
        ),
      ),
    );
  }
}
