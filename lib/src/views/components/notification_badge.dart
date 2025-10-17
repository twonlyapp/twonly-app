import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({
    required this.count,
    required this.child,
    super.key,
  });
  final String count;
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
              backgroundColor: Colors.red,
              child: Center(
                child: Transform.rotate(
                  angle: infinity ? 90 * (3.141592653589793 / 180) : 0,
                  child: Text(
                    infinity ? '8' : count,
                    style: const TextStyle(
                      color: Colors.white, // Text color
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
