import 'package:flutter/material.dart';
import 'package:twonly/src/components/image_editor/data/layer.dart';

/// Emoji layer
class EmojiLayer extends StatefulWidget {
  final EmojiLayerData layerData;
  final VoidCallback? onUpdate;

  const EmojiLayer({
    super.key,
    required this.layerData,
    this.onUpdate,
  });

  @override
  createState() => _EmojiLayerState();
}

class _EmojiLayerState extends State<EmojiLayer> {
  double initialRotation = 0;
  Offset initialOffset = Offset.zero;
  double initialScale = 1.0;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();

    if (widget.layerData.offset.dy == 0) {
      // Set the initial offset to the center of the screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          widget.layerData.offset = Offset(
              MediaQuery.of(context).size.width / 2 - 64,
              MediaQuery.of(context).size.height / 2 - 64 - 100);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.layerData.offset.dx,
      top: widget.layerData.offset.dy,
      child: GestureDetector(
        onTap: () {},
        onScaleStart: (details) {
          // Store the initial scale and rotation
          initialScale = widget.layerData.size; // Reset initial scale
          initialRotation = widget.layerData.rotation;
          initialOffset = widget.layerData.offset;
        },
        onScaleUpdate: (details) {
          setState(() {
            // Update the size based on the scale factor

            widget.layerData.size = initialScale * details.scale;

            // Update the rotation based on the rotation angle
            widget.layerData.rotation = initialRotation + details.rotation;

            // Update the position based on the translation
            final RenderBox renderBox =
                _key.currentContext?.findRenderObject() as RenderBox;
            var dx = details.focalPoint.dx - (renderBox.size.width / 2);
            var dy = details.focalPoint.dy - (renderBox.size.height / 2 + 34);
            widget.layerData.offset = Offset(dx, dy);
          });
        },
        onScaleEnd: (details) {
          // Optionally, you can handle the end of the scale gesture here
        },
        child: Transform.rotate(
          key: _key,
          angle: widget.layerData.rotation,
          child: Container(
            padding: const EdgeInsets.all(34),
            color: Colors.transparent,
            child: Text(
              widget.layerData.text.toString(),
              style: TextStyle(
                fontSize: widget.layerData.size,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
