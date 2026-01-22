import 'package:flutter/material.dart';
import 'package:hand_signature/signature.dart';
import 'package:twonly/src/views/camera/share_image_editor/image_item.dart';

/// Layer class with some common properties
class Layer {
  Layer({
    required this.key,
    this.offset = Offset.zero,
    this.opacity = 1,
    this.isEditing = false,
    this.isDeleted = false,
    this.hasCustomActionButtons = false,
    this.showCustomButtons = true,
    this.rotation = 0,
    this.scale = 1,
  });
  Key key;
  Offset offset;
  double rotation;
  double scale;
  double opacity;
  bool isEditing;
  bool isDeleted;
  bool hasCustomActionButtons;
  bool showCustomButtons;
}

class BackgroundLayerData extends Layer {
  BackgroundLayerData({
    required super.key,
    required this.image,
  });
  ImageItem image;
  bool imageLoaded = false;
}

class LinkPreviewLayerData extends Layer {
  LinkPreviewLayerData({
    required super.key,
    required this.link,
  });
  Uri link;
}

class FilterLayerData extends Layer {
  FilterLayerData({
    required super.key,
    this.page = 1,
  });
  int page = 1;
}

class EmojiLayerData extends Layer {
  EmojiLayerData({
    required super.key,
    this.text = '',
    this.size = 94,
    super.offset,
    super.opacity,
    super.rotation,
    super.scale,
    super.isEditing,
  });
  String text;
  double size;
}

class TextLayerData extends Layer {
  TextLayerData({
    required super.key,
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

class DrawLayerData extends Layer {
  DrawLayerData({
    required super.key,
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
