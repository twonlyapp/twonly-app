import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:twonly/src/views/camera/share_image_editor/layer_data.dart';

class BackgroundLayer extends StatefulWidget {
  const BackgroundLayer({
    required this.layerData,
    super.key,
    this.onUpdate,
  });
  final BackgroundLayerData layerData;
  final VoidCallback? onUpdate;

  @override
  State<BackgroundLayer> createState() => _BackgroundLayerState();
}

class _BackgroundLayerState extends State<BackgroundLayer> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.layerData.imageLoaded = true;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final scImage = widget.layerData.image.image;
    if (scImage == null || scImage.image == null) return Container();
    return Container(
      width: widget.layerData.image.width.toDouble(),
      height: widget.layerData.image.height.toDouble(),
      padding: EdgeInsets.zero,
      color: Colors.transparent,
      child: CustomPaint(
        painter: UiImagePainter(scImage.image!),
      ),
    );
  }
}

class UiImagePainter extends CustomPainter {
  UiImagePainter(this.image);
  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final sizes = applyBoxFit(BoxFit.contain, imageSize, size);

    final destRect = Alignment.center.inscribe(
      sizes.destination,
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imageSize.width, imageSize.height),
      destRect,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant UiImagePainter oldDelegate) {
    return image != oldDelegate.image;
  }
}
