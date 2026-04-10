import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/loader/ripple.loader.dart';

class ConnectionStatusBadge extends StatelessWidget {
  const ConnectionStatusBadge({
    required this.child,
    super.key,
  });
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isConnected = context.watch<CustomChangeProvider>().isConnected;
    return Stack(
      children: [
        if (!isConnected)
          const Positioned.fill(
            child: SpinKitRipple(
              color: Colors.red,
            ),
          ),
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isConnected
                  ? context.color.primary.withAlpha(100)
                  : Colors.red,
            ),
          ),
          padding: const EdgeInsets.all(0.5),
          child: Center(
            child: child,
          ),
        ),
      ],
    );
  }
}
