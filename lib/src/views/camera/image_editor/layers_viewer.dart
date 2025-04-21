import 'package:flutter/material.dart';
import 'package:twonly/src/views/camera/image_editor/data/layer.dart';
import 'package:twonly/src/views/camera/image_editor/layers/background_layer.dart';
import 'package:twonly/src/views/camera/image_editor/layers/draw_layer.dart';
import 'package:twonly/src/views/camera/image_editor/layers/emoji_layer.dart';
import 'package:twonly/src/views/camera/image_editor/layers/filter_layer.dart';
import 'package:twonly/src/views/camera/image_editor/layers/text_layer.dart';

/// View stacked layers (unbounded height, width)
class LayersViewer extends StatelessWidget {
  final List<Layer> layers;
  final Function()? onUpdate;

  const LayersViewer({
    super.key,
    required this.layers,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ...layers.whereType<BackgroundLayerData>().map((layerItem) {
          return BackgroundLayer(
            layerData: layerItem,
            onUpdate: onUpdate,
          );
        }),
        ...layers.whereType<FilterLayerData>().map((layerItem) {
          return FilterLayer(
            layerData: layerItem,
          );
        }),
        ...layers
            .where((layerItem) =>
                layerItem is EmojiLayerData || layerItem is DrawLayerData)
            .map((layerItem) {
          if (layerItem is EmojiLayerData) {
            return EmojiLayer(
              layerData: layerItem,
              onUpdate: onUpdate,
            );
          } else if (layerItem is DrawLayerData) {
            return DrawLayer(
              layerData: layerItem,
              onUpdate: onUpdate,
            );
          }
          return Container();
        }),
        ...layers.whereType<TextLayerData>().map((layerItem) {
          return TextLayer(
            layerData: layerItem,
            onUpdate: onUpdate,
          );
        }),
      ],
    );
  }
}
