import 'package:flutter/material.dart';

class MediaViewSizing extends StatelessWidget {
  final Widget child;

  const MediaViewSizing(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: AspectRatio(
                aspectRatio: 9 / 16,
                // padding: EdgeInsets.symmetric(vertical: 50, horizontal: 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
