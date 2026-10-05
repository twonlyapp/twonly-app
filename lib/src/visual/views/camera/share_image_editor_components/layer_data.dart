import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hand_signature/signature.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/image_item.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/link_preview/parser/base.dart';

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
  Metadata? metadata;
  bool error = false;
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

class StickerLayerData extends Layer {
  StickerLayerData({
    required super.key,
    required this.webp,
    required this.contentHash,
    required this.width,
    required this.height,
    this.size = 160,
    super.offset,
    super.opacity,
    super.rotation,
    super.scale,
    super.isEditing,
  });

  final Uint8List webp;
  final String contentHash;
  final int width;
  final int height;
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
