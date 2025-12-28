import 'package:flutter/material.dart';
import 'package:twonly/src/views/camera/image_editor/data/layer.dart';

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
  Widget build(BuildContext context) {
    return Container(
      width: widget.layerData.image.width.toDouble(),
      height: widget.layerData.image.height.toDouble(),
      // color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.zero,
      child: Image.memory(
        widget.layerData.image.bytes,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.layerData.imageLoaded = true;
            });
          }
          return child;
        },
      ),
    );
  }
}
