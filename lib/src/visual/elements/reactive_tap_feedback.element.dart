import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class ReactiveTapFeedback extends StatefulWidget {
  const ReactiveTapFeedback({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.behavior = HitTestBehavior.opaque,
    this.alwaysAnimate = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final HitTestBehavior behavior;
  final bool alwaysAnimate;

  @override
  State<ReactiveTapFeedback> createState() => _ReactiveTapFeedbackState();
}

class _ReactiveTapFeedbackState extends State<ReactiveTapFeedback>
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

  bool get _shouldAnimate =>
      widget.alwaysAnimate ||
      widget.onTap != null ||
      widget.onLongPress != null;

  void _onTapDown(TapDownDetails details) {
    if (_shouldAnimate) {
      _controller.animateTo(
        1,
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_shouldAnimate) {
      _bounce();
    }
  }

  void _onTapCancel() {
    if (_shouldAnimate) {
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

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _shouldAnimate ? _onTapDown : null,
      onTapUp: _shouldAnimate ? _onTapUp : null,
      onTapCancel: _shouldAnimate ? _onTapCancel : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Transform.scale(
        scale: scale,
        child: widget.child,
      ),
    );
  }
}
