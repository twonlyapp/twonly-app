import 'package:flutter/material.dart';
import 'package:twonly/src/components/image_editor/data/image_item.dart';

/// Layer class with some common properties
class Layer {
  Offset offset;
  double rotation, scale, opacity;

  Layer({
    this.offset = const Offset(64, 64),
    this.opacity = 1,
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
  });
}

/// Attributes used by [TextLayer]
class TextLayerData extends Layer {
  String text;

  TextLayerData({
    required this.text,
    super.offset,
    super.opacity,
    super.rotation,
    super.scale,
  });
}

/// Attributes used by [TextLayer]
class LinkLayerData extends Layer {
  String text;
  double size;
  Color color, background;
  double backgroundOpacity;
  TextAlign align;

  LinkLayerData({
    required this.text,
    this.size = 64,
    this.color = Colors.white,
    this.background = Colors.transparent,
    this.backgroundOpacity = 0,
    this.align = TextAlign.left,
    super.offset,
    super.opacity,
    super.rotation,
    super.scale,
  });
}
