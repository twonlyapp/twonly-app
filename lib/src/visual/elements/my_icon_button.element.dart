import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:twonly/src/utils/misc.dart';
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

class _MyIconButtonState extends State<MyIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
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
    final scale = 1.0 - (_controller.value * 0.02);
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
