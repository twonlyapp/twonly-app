import 'package:flutter/material.dart';
import 'package:twonly/src/components/image_editor/data/image_item.dart';

/// Layer class with some common properties
class Layer {
  Offset offset;
  double rotation, scale, opacity;
  bool isEditing;
  bool isDeleted;

  Layer({
    this.offset = const Offset(0, 0),
    this.opacity = 1,
    this.isEditing = false,
    this.isDeleted = false,
    this.rotation = 0,
    this.scale = 1,
  });
}

/// Attributes used by [BackgroundLayer]
class BackgroundLayerData extends Layer {
  ImageItem image;

  BackgroundLayerData({
    required this.image,
  });
}

/// Attributes used by [EmojiLayer]
class EmojiLayerData extends Layer {
  String text;
  double size;

  EmojiLayerData({
    this.text = '',
    this.size = 64,
    super.offset,
    super.opacity,
    super.rotation,
    super.scale,
    super.isEditing,
  });
}

/// Attributes used by [ImageLayer]
class ImageLayerData extends Layer {
  ImageItem image;
  double size;

  ImageLayerData({
    required this.image,
    this.size = 64,
    super.offset,
    super.opacity,
    super.rotation,
    super.scale,
    super.isEditing,
  });
}

/// Attributes used by [TextLayer]
class TextLayerData extends Layer {
  String text;
  TextLayerData({
    this.text = "",
    super.offset,
    super.opacity,
    super.rotation,
    super.scale,
    super.isEditing = true,
  });
}
