import 'package:flutter/material.dart';
import 'package:twonly/src/components/image_editor/data/layer.dart';

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
  double initialRotation = 0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: widget.layerData.offset.dy,
      child: GestureDetector(
        onTap: widget.editable ? () {} : null,
        onScaleUpdate: widget.editable
            ? (detail) {
                if (detail.pointerCount == 1) {
                  widget.layerData.offset = Offset(
                    0,
                    widget.layerData.offset.dy + detail.focalPointDelta.dy,
                  );
                }
                setState(() {});
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(100),
          ),
          child: Text(
            widget.layerData.text.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}
