import 'package:flutter/material.dart';

class MediaViewSizingHelper extends StatefulWidget {
  const MediaViewSizingHelper({
    required this.child,
    super.key,
    this.requiredHeight,
    this.bottomNavigation,
    this.additionalPadding,
  });

  const MediaViewSizingHelper.cameraEditor({
    required this.child,
    required this.bottomNavigation,
    super.key,
  }) : requiredHeight = 59,
       additionalPadding = null;

  final double? requiredHeight;
  final double? additionalPadding;
  final Widget? bottomNavigation;
  final Widget child;

  @override
  State<MediaViewSizingHelper> createState() => _MediaViewSizingHelperState();
}

class _MediaViewSizingHelperState extends State<MediaViewSizingHelper> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final availableHeight =
              constraints.maxHeight - (widget.additionalPadding ?? 0);
          final aspectRatioHeight = (availableWidth * 16) / 9;
          final bottomNavigationHeight = widget.requiredHeight ?? 0;
          final needToDownSizeImage =
              aspectRatioHeight + bottomNavigationHeight > availableHeight;

          Widget imageChild = Align(
            alignment: Alignment.topCenter,
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: widget.child,
              ),
            ),
          );

          Widget bottomNavigation = const SizedBox.shrink();

          if (widget.bottomNavigation != null) {
            if (needToDownSizeImage) {
              imageChild = Expanded(child: imageChild);
              bottomNavigation = SizedBox(
                height: widget.requiredHeight,
                child: widget.bottomNavigation,
              );
            } else {
              bottomNavigation = Expanded(child: widget.bottomNavigation!);
            }
          }

          return Container(
            constraints: BoxConstraints(maxHeight: availableHeight),
            child: Column(
              children: [imageChild, bottomNavigation],
            ),
          );
        },
      ),
    );
  }
}
