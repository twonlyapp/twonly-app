import 'package:flutter/material.dart';

class AnimatedNewMessage extends StatefulWidget {
  const AnimatedNewMessage({
    required this.child,
    required this.messageId,
    required this.animateIds,
    super.key,
  });

  final Widget child;
  final String messageId;
  final Set<String> animateIds;

  @override
  State<AnimatedNewMessage> createState() => _AnimatedNewMessageState();
}

class _AnimatedNewMessageState extends State<AnimatedNewMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _didAnimate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation =
        Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.decelerate,
          ),
        );
    _opacityAnimation =
        Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
          ),
        );

    if (widget.animateIds.contains(widget.messageId)) {
      widget.animateIds.remove(widget.messageId);
      _didAnimate = true;
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_didAnimate) {
      return widget.child;
    }
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
      axisAlignment: 1,
      child: ScaleTransition(
        scale: _scaleAnimation,
        alignment: Alignment.bottomRight,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}
