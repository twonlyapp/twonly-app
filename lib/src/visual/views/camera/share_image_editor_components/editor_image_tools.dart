import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Integer bounds of an editor selection in the rendered image.
class EditorImageCrop {
  const EditorImageCrop({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;
}

/// Top-left layer offset that places the visible sticker in the editor center.
/// Sticker layers include interaction padding around the visible image.
Offset centeredStickerLayerOffset({
  required Size editorSize,
  required Size displayedStickerSize,
  double interactionPadding = 36,
}) =>
    editorSize.center(Offset.zero) -
    Offset(
      displayedStickerSize.width / 2 + interactionPadding,
      displayedStickerSize.height / 2 + interactionPadding,
    );

/// A single rendered editor frame whose colors can be sampled repeatedly
/// without taking a new screenshot for every pointer movement.
class EditorImageColorSampler {
  const EditorImageColorSampler({
    required this.bytes,
    required this.imageWidth,
    required this.imageHeight,
  });

  final ByteData bytes;
  final int imageWidth;
  final int imageHeight;

  static Future<EditorImageColorSampler?> fromImage(ui.Image image) async {
    final bytes = await image.toByteData();
    if (bytes == null) return null;
    return EditorImageColorSampler(
      bytes: bytes,
      imageWidth: image.width,
      imageHeight: image.height,
    );
  }

  Color? sample(Offset point, Size editorSize) {
    final pixel = editorPointToImagePixel(
      point: point,
      editorSize: editorSize,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
    if (pixel == null) return null;

    final offset = (pixel.y * imageWidth + pixel.x) * 4;
    if (offset + 3 >= bytes.lengthInBytes) return null;
    return Color.fromARGB(
      bytes.getUint8(offset + 3),
      bytes.getUint8(offset),
      bytes.getUint8(offset + 1),
      bytes.getUint8(offset + 2),
    );
  }
}

/// Maps a logical editor position to one pixel in a rendered canvas image.
({int x, int y})? editorPointToImagePixel({
  required Offset point,
  required Size editorSize,
  required int imageWidth,
  required int imageHeight,
}) {
  if (editorSize.isEmpty || imageWidth < 1 || imageHeight < 1) return null;
  if (point.dx < 0 ||
      point.dy < 0 ||
      point.dx >= editorSize.width ||
      point.dy >= editorSize.height) {
    return null;
  }

  return (
    x: (point.dx / editorSize.width * imageWidth).floor().clamp(
      0,
      imageWidth - 1,
    ),
    y: (point.dy / editorSize.height * imageHeight).floor().clamp(
      0,
      imageHeight - 1,
    ),
  );
}

/// Maps a logical editor selection to a non-empty pixel crop.
EditorImageCrop editorRectToImageCrop({
  required Rect selection,
  required Size editorSize,
  required int imageWidth,
  required int imageHeight,
}) {
  if (editorSize.isEmpty || imageWidth < 1 || imageHeight < 1) {
    throw ArgumentError('The editor and image dimensions must be positive.');
  }

  final bounded = selection.intersect(Offset.zero & editorSize);
  if (bounded.isEmpty) {
    throw ArgumentError('The selection does not overlap the editor.');
  }

  final left = (bounded.left / editorSize.width * imageWidth).floor().clamp(
    0,
    imageWidth - 1,
  );
  final top = (bounded.top / editorSize.height * imageHeight).floor().clamp(
    0,
    imageHeight - 1,
  );
  final right = (bounded.right / editorSize.width * imageWidth).ceil().clamp(
    left + 1,
    imageWidth,
  );
  final bottom = (bounded.bottom / editorSize.height * imageHeight)
      .ceil()
      .clamp(top + 1, imageHeight);

  return EditorImageCrop(
    x: left,
    y: top,
    width: right - left,
    height: bottom - top,
  );
}

/// Crops an encoded screenshot using logical coordinates from the editor.
Uint8List cropEditorImage({
  required Uint8List encodedImage,
  required Rect selection,
  required Size editorSize,
}) {
  final decoded = img.decodeImage(encodedImage);
  if (decoded == null) throw const FormatException('Invalid editor image.');

  final crop = editorRectToImageCrop(
    selection: selection,
    editorSize: editorSize,
    imageWidth: decoded.width,
    imageHeight: decoded.height,
  );
  final cropped = img.copyCrop(
    decoded,
    x: crop.x,
    y: crop.y,
    width: crop.width,
    height: crop.height,
  );
  return img.encodePng(cropped);
}
