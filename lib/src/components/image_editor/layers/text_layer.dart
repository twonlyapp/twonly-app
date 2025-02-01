import 'package:flutter/material.dart';
import 'package:twonly/src/components/image_editor/data/layer.dart';
import 'package:twonly/src/components/image_editor/image_editor.dart';
import 'package:twonly/src/components/image_editor/modules/text_layer_overlay.dart';

/// Text layer
class TextLayer extends StatefulWidget {
  final TextLayerData layerData;
  final VoidCallback? onUpdate;
  final bool editable;

  const TextLayer({
    super.key,
    required this.layerData,
    this.onUpdate,
    this.editable = false,
  });
  @override
  createState() => _TextViewState();
}

class _TextViewState extends State<TextLayer> {
  double initialSize = 0;
  double initialRotation = 0;

  @override
  Widget build(BuildContext context) {
    initialSize = widget.layerData.size;
    initialRotation = widget.layerData.rotation;

    return Positioned(
      left: widget.layerData.offset.dx,
      top: widget.layerData.offset.dy,
      child: GestureDetector(
        onTap: widget.editable
            ? () {
                showModalBottomSheet(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10),
                      topLeft: Radius.circular(10),
                    ),
                  ),
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return TextLayerOverlay(
                      index: layers.indexOf(widget.layerData),
                      layer: widget.layerData,
                      onUpdate: () {
                        if (widget.onUpdate != null) widget.onUpdate!();
                        setState(() {});
                      },
                    );
                  },
                );
              }
            : null,
        onScaleUpdate: widget.editable
            ? (detail) {
                if (detail.pointerCount == 1) {
                  widget.layerData.offset = Offset(
                    widget.layerData.offset.dx + detail.focalPointDelta.dx,
                    widget.layerData.offset.dy + detail.focalPointDelta.dy,
                  );
                } else if (detail.pointerCount == 2) {
                  widget.layerData.size =
                      initialSize + detail.scale * (detail.scale > 1 ? 1 : -1);

                  // print('angle');
                  // print(detail.rotation);
                  widget.layerData.rotation = detail.rotation;
                }
                setState(() {});
              }
            : null,
        child: Transform.rotate(
          angle: widget.layerData.rotation,
          child: Container(
            padding: const EdgeInsets.all(64),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.layerData.background
                    .withOpacity(widget.layerData.backgroundOpacity),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.layerData.text.toString(),
                textAlign: widget.layerData.align,
                style: TextStyle(
                  color: widget.layerData.color,
                  fontSize: widget.layerData.size,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
