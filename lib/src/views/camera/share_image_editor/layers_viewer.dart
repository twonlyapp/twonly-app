import 'package:flutter/material.dart';
import 'package:twonly/src/views/camera/share_image_editor/data/layer.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/background.layer.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/draw.layer.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/emoji.layer.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/filter.layer.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/text.layer.dart';

/// View stacked layers (unbounded height, width)
class LayersViewer extends StatelessWidget {
  const LayersViewer({
    required this.layers,
    super.key,
    this.onUpdate,
  });
  final List<Layer> layers;
  final void Function()? onUpdate;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ...layers.whereType<BackgroundLayerData>().map((layerItem) {
          return BackgroundLayer(
            key: layerItem.key,
            layerData: layerItem,
            onUpdate: onUpdate,
          );
        }),
        ...layers.whereType<FilterLayerData>().map((layerItem) {
          return FilterLayer(
            key: layerItem.key,
            layerData: layerItem,
          );
        }),
        ...layers
            .where(
          (layerItem) =>
              layerItem is EmojiLayerData ||
              layerItem is DrawLayerData ||
              layerItem is TextLayerData,
        )
            .map((layerItem) {
          if (layerItem is EmojiLayerData) {
            return EmojiLayer(
              key: layerItem.key,
              layerData: layerItem,
              onUpdate: onUpdate,
            );
          } else if (layerItem is DrawLayerData) {
            return DrawLayer(
              key: layerItem.key,
              layerData: layerItem,
              onUpdate: onUpdate,
            );
          } else if (layerItem is TextLayerData) {
            return TextLayer(
              key: layerItem.key,
              layerData: layerItem,
              onUpdate: onUpdate,
            );
          }
          return Container();
        }),
      ],
    );
  }
}
