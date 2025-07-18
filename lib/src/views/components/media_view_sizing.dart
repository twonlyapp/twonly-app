import 'package:flutter/material.dart';

class MediaViewSizing extends StatefulWidget {
  const MediaViewSizing({
    required this.child,
    super.key,
    this.requiredHeight,
    this.bottomNavigation,
  });

  final double? requiredHeight;
  final Widget? bottomNavigation;
  final Widget child;

  @override
  State<MediaViewSizing> createState() => _MediaViewSizingState();
}

class _MediaViewSizingState extends State<MediaViewSizing> {
  @override
  Widget build(BuildContext context) {
    var needToDownSizeImage = false;

    if (widget.requiredHeight != null) {
      // Get the screen size and safe area padding
      final screenSize = MediaQuery.of(context).size;
      final safeAreaPadding = MediaQuery.of(context).padding;

      // Calculate the available width and height
      final availableWidth = screenSize.width;
      final availableHeight =
          screenSize.height - safeAreaPadding.top - safeAreaPadding.bottom;

      final aspectRatioWidth = availableWidth;
      final aspectRatioHeight = (aspectRatioWidth * 16) / 9;
      if (aspectRatioHeight < availableHeight) {
        if ((screenSize.height - widget.requiredHeight!) < aspectRatioHeight) {
          needToDownSizeImage = true;
        }
      }
    }

    Widget imageChild = Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: widget.child,
          ),
        ),
      ),
    );

    Widget bottomNavigation = Container();

    if (widget.bottomNavigation != null) {
      if (needToDownSizeImage) {
        imageChild = Expanded(child: imageChild);
        bottomNavigation = widget.bottomNavigation!;
      } else {
        bottomNavigation = Expanded(child: widget.bottomNavigation!);
      }
    }

    return SafeArea(
      child: Column(
        children: [imageChild, bottomNavigation],
      ),
    );
  }
}
