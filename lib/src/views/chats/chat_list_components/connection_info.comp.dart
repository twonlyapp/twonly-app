import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/misc.dart';

class ConnectionInfo extends StatefulWidget {
  const ConnectionInfo({super.key});

  @override
  State<ConnectionInfo> createState() => _ConnectionInfoWidgetState();
}

class _ConnectionInfoWidgetState extends State<ConnectionInfo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnim;
  late Animation<double> _widthAnim;

  bool showAnimation = false;

  final double minBarWidth = 40;
  final double maxBarWidth = 150;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _positionAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _widthAnim = TweenSequence([
      TweenSequenceItem(
          tween: Tween<double>(begin: minBarWidth, end: maxBarWidth),
          weight: 50),
      TweenSequenceItem(
          tween: Tween<double>(begin: maxBarWidth, end: minBarWidth),
          weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Delay start by 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.repeat(reverse: true);
        setState(() {
          showAnimation = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!showAnimation || gIsDemoUser) return Container();
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth,
      height: 1,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final barWidth = _widthAnim.value;
          final left = _positionAnim.value * (screenWidth - barWidth);
          return Stack(
            children: [
              Positioned(
                left: left,
                top: 0,
                bottom: 0,
                child: Container(
                  width: barWidth,
                  decoration: BoxDecoration(
                    color: context.color.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
