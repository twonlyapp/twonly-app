import 'package:flutter/material.dart';
import 'package:twonly/src/components/image_editor/data/layer.dart';
import 'package:twonly/src/components/image_editor/layers/background_layer.dart';
import 'package:twonly/src/components/image_editor/layers/draw_layer.dart';
import 'package:twonly/src/components/image_editor/layers/emoji_layer.dart';
import 'package:twonly/src/components/image_editor/layers/image_layer.dart';
import 'package:twonly/src/components/image_editor/layers/text_layer.dart';

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
        // Background and Image layers at the bottom
        ...layers
            .where((layerItem) =>
                layerItem is BackgroundLayerData || layerItem is ImageLayerData)
            .map((layerItem) {
          if (layerItem is BackgroundLayerData) {
            return BackgroundLayer(
              layerData: layerItem,
              onUpdate: onUpdate,
            );
          } else if (layerItem is ImageLayerData) {
            return ImageLayer(
              layerData: layerItem,
              onUpdate: onUpdate,
            );
          }
          return Container(); // Fallback, should not reach here
        }),

        // Draw layer (if needed, can be placed anywhere)
        ...layers.whereType<DrawLayerData>().map((layerItem) {
          return DrawLayer(
            layerData: layerItem,
            onUpdate: onUpdate,
          );
        }),

        // Emoji and Text layers at the top
        ...layers
            .where((layerItem) =>
                layerItem is EmojiLayerData || layerItem is TextLayerData)
            .map((layerItem) {
          if (layerItem is EmojiLayerData) {
            return EmojiLayer(
              layerData: layerItem,
              onUpdate: onUpdate,
            );
          } else if (layerItem is TextLayerData) {
            return TextLayer(
              layerData: layerItem,
              onUpdate: onUpdate,
            );
          }
          return Container(); // Fallback, should not reach here
        }),
      ],
    );
  }
}
