import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:twonly/src/utils/misc.dart';

class TwonlyPresentOverlay extends StatelessWidget {
  const TwonlyPresentOverlay({
    required this.onTap,
    super.key,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Lottie.asset(
                'assets/animations/present.lottie.lottie',
              ),
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 200),
              child: Text(
                context.lang.mediaViewerTwonlyTapToOpen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
