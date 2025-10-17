import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageItem {
  ImageItem([dynamic image]) {
    if (image != null) unawaited(load(image));
  }
  int width = 1;
  int height = 1;
  Uint8List bytes = Uint8List.fromList([]);
  Completer<bool> loader = Completer<bool>();

  Future<void> load(dynamic image) async {
    loader = Completer<bool>();

    if (image is ImageItem) {
      bytes = image.bytes;

      height = image.height;
      width = image.width;

      return loader.complete(true);
    } else if (image is Uint8List) {
      bytes = image;
      final decodedImage = await decodeImageFromList(bytes);

      height = decodedImage.height;
      width = decodedImage.width;

      return loader.complete(true);
    } else {
      return loader.complete(false);
    }
  }
}
