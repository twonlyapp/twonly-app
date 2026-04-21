import 'package:flutter/material.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/background.layer.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/draw.layer.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/emoji.layer.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/filter.layer.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/link_preview.layer.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/text.layer.dart';

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
          if (!layerItem.isEditing) {
            return BackgroundLayer(
              key: layerItem.key,
              layerData: layerItem,
              onUpdate: onUpdate,
            );
          } else {
            return Container();
          }
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
                  layerItem is LinkPreviewLayerData ||
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
              } else if (layerItem is LinkPreviewLayerData) {
                return LinkPreviewLayer(
                  key: layerItem.key,
                  layerData: layerItem,
                  onUpdate: onUpdate,
                );
              }
              return Container();
            }),
        ...layers.whereType<BackgroundLayerData>().map((layerItem) {
          if (layerItem.isEditing) {
            return BackgroundLayer(
              key: layerItem.key,
              layerData: layerItem,
              onUpdate: onUpdate,
            );
          } else {
            return Container();
          }
        }),
      ],
    );
  }
}
