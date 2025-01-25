import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const NotificationBadge(
      {super.key, required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return child;
    return Stack(
      children: [
        child,
        Positioned(
          right: 5,
          top: 0,
          child: Container(
            padding: EdgeInsets.all(5.0), // Add some padding
            decoration: BoxDecoration(
              color: Colors.red, // Background color
              shape: BoxShape.circle, // Make it circular
            ),
            child: Center(
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: Colors.white, // Text color
                  fontSize: 10,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
