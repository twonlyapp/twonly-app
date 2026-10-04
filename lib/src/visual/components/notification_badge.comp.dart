import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

class NotificationBadgeComp extends StatelessWidget {
  const NotificationBadgeComp({
    required this.count,
    required this.child,
    this.backgroundColor,
    this.textColor,
    super.key,
  });
  final String count;
  final Color? backgroundColor;
  final Color? textColor;
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
              backgroundColor: backgroundColor ?? context.color.error,
              child: Center(
                child: Transform.rotate(
                  angle: infinity ? 90 * (3.141592653589793 / 180) : 0,
                  child: Text(
                    infinity ? '8' : count,
                    style: TextStyle(
                      color: textColor ?? context.color.onError,
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
