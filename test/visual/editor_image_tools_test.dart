import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:twonly/src/visual/views/camera/share_image_editor_components/editor_image_tools.dart';

void main() {
  test('maps editor points to rendered image pixels', () {
    expect(
      editorPointToImagePixel(
        point: const Offset(25, 100),
        editorSize: const Size(100, 200),
        imageWidth: 400,
        imageHeight: 800,
      ),
      (x: 100, y: 400),
    );
    expect(
      editorPointToImagePixel(
        point: const Offset(100, 10),
        editorSize: const Size(100, 200),
        imageWidth: 400,
        imageHeight: 800,
      ),
      isNull,
    );
  });

  test('maps fractional selections outward to complete pixels', () {
    final crop = editorRectToImageCrop(
      selection: const Rect.fromLTRB(10.2, 20.2, 49.8, 79.8),
      editorSize: const Size(100, 100),
      imageWidth: 200,
      imageHeight: 300,
    );

    expect((crop.x, crop.y), (20, 60));
    expect((crop.width, crop.height), (80, 180));
  });

  test('reuses one rendered frame for multiple color samples', () {
    final bytes = ByteData(8)
      ..setUint8(0, 10)
      ..setUint8(1, 20)
      ..setUint8(2, 30)
      ..setUint8(3, 255)
      ..setUint8(4, 40)
      ..setUint8(5, 50)
      ..setUint8(6, 60)
      ..setUint8(7, 255);
    final sampler = EditorImageColorSampler(
      bytes: bytes,
      imageWidth: 2,
      imageHeight: 1,
    );

    expect(
      sampler.sample(const Offset(10, 5), const Size(100, 10)),
      const Color.fromARGB(255, 10, 20, 30),
    );
    expect(
      sampler.sample(const Offset(90, 5), const Size(100, 10)),
      const Color.fromARGB(255, 40, 50, 60),
    );
  });

  test('centers a sticker independently of the selected source area', () {
    final offset = centeredStickerLayerOffset(
      editorSize: const Size(300, 500),
      displayedStickerSize: const Size(120, 80),
    );
    final visibleCenter = offset + const Offset(36 + 60, 36 + 40);

    expect(visibleCenter, const Offset(150, 250));
  });

  test('crops the selected editor region', () {
    final source = img.Image(width: 4, height: 4);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgba(x, y, x * 50, y * 50, 0, 255);
      }
    }

    final bytes = cropEditorImage(
      encodedImage: Uint8List.fromList(img.encodePng(source)),
      selection: const Rect.fromLTWH(1, 1, 2, 2),
      editorSize: const Size(4, 4),
    );
    final cropped = img.decodePng(bytes)!;

    expect((cropped.width, cropped.height), (2, 2));
    expect(cropped.getPixel(0, 0).r, 50);
    expect(cropped.getPixel(0, 0).g, 50);
    expect(cropped.getPixel(1, 1).r, 100);
    expect(cropped.getPixel(1, 1).g, 100);
  });
}
