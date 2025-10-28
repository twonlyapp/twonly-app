// ignore_for_file: comment_references

import 'package:flutter/material.dart';
import 'package:hand_signature/signature.dart';
import 'package:twonly/src/views/camera/image_editor/data/image_item.dart';

/// Layer class with some common properties
class Layer {
  Layer({
    this.offset = Offset.zero,
    this.opacity = 1,
    this.isEditing = false,
    this.isDeleted = false,
    this.hasCustomActionButtons = false,
    this.showCustomButtons = true,
    this.rotation = 0,
    this.scale = 1,
  });
  Offset offset;
  double rotation;
  double scale;
  double opacity;
  bool isEditing;
  bool isDeleted;
  bool hasCustomActionButtons;
  bool showCustomButtons;
}

/// Attributes used by [BackgroundLayer]
class BackgroundLayerData extends Layer {
  BackgroundLayerData({
    required this.image,
  });
  ImageItem image;
}

class FilterLayerData extends Layer {
  int page = 1;
}

/// Attributes used by [EmojiLayer]
class EmojiLayerData extends Layer {
  EmojiLayerData({
    this.text = '',
    this.size = 64,
    super.offset,
    super.opacity,
    super.rotation,
    super.scale,
    super.isEditing,
  });
  String text;
  double size;
}

/// Attributes used by [TextLayer]
class TextLayerData extends Layer {
  TextLayerData({
    required this.textLayersBefore,
    this.text = '',
    super.offset,
    super.opacity,
    super.rotation,
    super.scale,
    super.isEditing = true,
  });
  String text;
  int textLayersBefore;
}

/// Attributes used by [DrawLayer]
class DrawLayerData extends Layer {
  // String text;
  DrawLayerData({
    super.offset,
    super.opacity,
    super.rotation,
    super.scale,
    super.hasCustomActionButtons = true,
    super.isEditing = true,
  });
  final control = HandSignatureControl(
    // ignore: prefer_const_constructors
    setup: () => SignaturePathSetup(
      args: {
        'color': null,
      },
    ),
  );
}
