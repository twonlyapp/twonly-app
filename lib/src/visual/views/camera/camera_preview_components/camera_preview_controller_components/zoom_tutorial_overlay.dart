import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ZoomTutorialOverlay extends StatefulWidget {
  const ZoomTutorialOverlay({
    required this.child,
    required this.hasZoomed,
    super.key,
  });

  final Widget child;
  final bool hasZoomed;

  @override
  State<ZoomTutorialOverlay> createState() => _ZoomTutorialOverlayState();
}

class _ZoomTutorialOverlayState extends State<ZoomTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dragAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _textOpacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 10),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 70),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 10),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 10),
    ]).animate(_controller);

    _textOpacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 15),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 15),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 5),
    ]).animate(_controller);

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.85), weight: 80),
    ]).animate(_controller);

    _dragAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 35),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: -75,
        ).chain(CurveTween(curve: Curves.easeInOutQuart)),
        weight: 40,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(-75), weight: 25),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hasZoomed) return widget.child;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: _dragAnim.value - 8,
                    right: 60,
                    child: Opacity(
                      opacity: _textOpacityAnim.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Drag to Zoom',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: _opacityAnim.value,
                    child: Transform.translate(
                      offset: Offset(0, _dragAnim.value),
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.handPointer,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
