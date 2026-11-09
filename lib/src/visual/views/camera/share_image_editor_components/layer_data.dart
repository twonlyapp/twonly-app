import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hand_signature/signature.dart';
import 'package:twonly/core/bridge/api.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/image_item.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/link_preview/parser/base.dart';

typedef EditorColorSampler = Color? Function(Offset position, Size editorSize);
typedef EditorColorSamplerLoader = Future<EditorColorSampler?> Function();

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

  /// Whether the location filter is the selected page.
  bool locationSelected = false;

  /// The location filter's fix, once it arrived.
  FilterLocation? location;

  /// Started with the editor, so the fix is usually there before the user
  /// swipes to the location filter.
  Future<FilterLocation?>? locationRequest;

  /// The location card, to measure where the receiver draws the map.
  final GlobalKey locationCardKey = GlobalKey();

  /// False while the editor captures the media. The location card never ends
  /// up in the pixels; the receiver draws the map from the sent coordinates.
  final showLocationCard = ValueNotifier<bool>(true);
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

abstract class TransformableStickerLayerData extends Layer {
  TransformableStickerLayerData({
    required super.key,
    this.size = 160,
    super.offset,
    super.opacity,
    super.rotation,
    super.scale,
    super.isEditing,
  });

  double size;
}

class StickerLayerData extends TransformableStickerLayerData {
  StickerLayerData({
    required super.key,
    required this.webp,
    required this.contentHash,
    required this.width,
    required this.height,
    super.size,
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
    this.colorSamplerLoader,
    super.offset,
    super.opacity,
    super.rotation,
    super.scale,
    super.hasCustomActionButtons = true,
    super.isEditing = true,
  });
  final EditorColorSamplerLoader? colorSamplerLoader;
  final control = HandSignatureControl(
    // ignore: prefer_const_constructors
    setup: () => SignaturePathSetup(
      args: {
        'color': null,
      },
    ),
  );
}
