import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({
    required this.count,
    required this.child,
    this.backgroundColor = Colors.red,
    this.textColor = Colors.white,
    super.key,
  });
  final String count;
  final Color backgroundColor;
  final Color textColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count == '0') return child;
    final infinity = count == '∞';
    return Stack(
      children: [
        child,
        Positioned(
          right: 3,
          top: 0,
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircleAvatar(
              backgroundColor: backgroundColor,
              child: Center(
                child: Transform.rotate(
                  angle: infinity ? 90 * (3.141592653589793 / 180) : 0,
                  child: Text(
                    infinity ? '8' : count,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
