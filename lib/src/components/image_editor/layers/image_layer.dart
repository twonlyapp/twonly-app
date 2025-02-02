import 'package:flutter/material.dart';
import 'package:twonly/src/components/image_editor/data/layer.dart';

/// Image layer that can be used to add overlay images and drawings
class ImageLayer extends StatefulWidget {
  final ImageLayerData layerData;
  final VoidCallback? onUpdate;
  final bool editable;

  const ImageLayer({
    super.key,
    required this.layerData,
    this.onUpdate,
    this.editable = false,
  });

  @override
  createState() => _ImageLayerState();
}

class _ImageLayerState extends State<ImageLayer> {
  double initialSize = 0;
  double initialRotation = 0;

  @override
  Widget build(BuildContext context) {
    initialSize = widget.layerData.size;
    initialRotation = widget.layerData.rotation;

    return Positioned.fill(
      child: SizedBox(
        width: widget.layerData.image.width.toDouble(),
        height: widget.layerData.image.height.toDouble(),
        child: Image.memory(widget.layerData.image.bytes),
      ),
    );
  }
}
