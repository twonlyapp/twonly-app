import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class TransitionImage extends StatelessWidget {
  const TransitionImage({
    required this.imageInfo,
    required this.animation,
    required this.thumbnailFit,
    required this.viewerFit,
    this.background,
    super.key,
  });

  final ImageInfo imageInfo;
  final Animation<double> animation;
  final BoxFit thumbnailFit;
  final BoxFit viewerFit;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => CustomPaint(
        painter: _TransitionImagePainter(
          image: imageInfo.image,
          scale: imageInfo.scale,
          t: animation.value,
          thumbnailFit: thumbnailFit,
          viewerFit: viewerFit,
          background: background,
        ),
      ),
    );
  }
}

class _TransitionImagePainter extends CustomPainter {
  const _TransitionImagePainter({
    required this.image,
    required this.scale,
    required this.t,
    required this.thumbnailFit,
    required this.viewerFit,
    required this.background,
  });

  final ui.Image? image;
  final double scale;
  final double t;
  final Color? background;
  final BoxFit thumbnailFit;
  final BoxFit viewerFit;

  static final _paint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;
  static const Alignment _alignment = Alignment.center;

  @override
  void paint(Canvas canvas, Size size) {
    final targetImage = image;
    if (targetImage == null || size.isEmpty) return;

    final outputSize = size;
    final inputSize = Size(
      targetImage.width.toDouble(),
      targetImage.height.toDouble(),
    );

    // Calculate source/destination dimensions for both start and end layout states
    final thumbnailSizes = applyBoxFit(thumbnailFit, inputSize / scale, size);
    final viewerSizes = applyBoxFit(viewerFit, inputSize / scale, size);

    // Linearly interpolate intermediate source framing and canvas bounds simultaneously
    final sourceSize =
        Size.lerp(thumbnailSizes.source, viewerSizes.source, t)! * scale;
    final destinationSize = Size.lerp(
      thumbnailSizes.destination,
      viewerSizes.destination,
      t,
    )!;

    final halfWidthDelta = (outputSize.width - destinationSize.width) / 2.0;
    final halfHeightDelta = (outputSize.height - destinationSize.height) / 2.0;
    final dx = halfWidthDelta + _alignment.x * halfWidthDelta;
    final dy = halfHeightDelta + _alignment.y * halfHeightDelta;
    final destinationRect = Offset(dx, dy) & destinationSize;

    final sourceRect = _alignment.inscribe(sourceSize, Offset.zero & inputSize);

    if (background != null) {
      canvas.drawRect(destinationRect.deflate(1), Paint()..color = background!);
    }
    canvas.drawImageRect(targetImage, sourceRect, destinationRect, _paint);
  }

  @override
  bool shouldRepaint(covariant _TransitionImagePainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.image != image ||
        oldDelegate.scale != scale;
  }
}
