import 'package:flutter/material.dart';
import 'package:twonly/src/views/camera/share_image_editor/layer_data.dart';

class LinkPreviewLayer extends StatefulWidget {
  const LinkPreviewLayer({
    required this.layerData,
    super.key,
    this.onUpdate,
  });
  final LinkPreviewLayerData layerData;
  final VoidCallback? onUpdate;

  @override
  State<LinkPreviewLayer> createState() => _LinkPreviewLayerState();
}

class _LinkPreviewLayerState extends State<LinkPreviewLayer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      child: Text(widget.layerData.link.toString()),
    );
  }
}
