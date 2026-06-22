import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

class AnimatedBellIcon extends StatefulWidget {
  const AnimatedBellIcon({super.key, this.color});
  final Color? color;

  @override
  State<AnimatedBellIcon> createState() => _AnimatedBellIconState();
}

class _AnimatedBellIconState extends State<AnimatedBellIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(_controller);

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _animation,
      alignment: Alignment.topCenter,
      child: Icon(
        Icons.notifications_active_rounded,
        size: 32,
        color: widget.color ?? context.color.primary,
      ),
    );
  }
}
