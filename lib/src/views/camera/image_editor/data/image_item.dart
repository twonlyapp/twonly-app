import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:exif/exif.dart';
import 'package:image/image.dart' as img;

class ImageItem {
  int width = 1;
  int height = 1;
  Uint8List bytes = Uint8List.fromList([]);
  Completer<bool> loader = Completer<bool>();

  ImageItem([dynamic image]) {
    if (image != null) load(image);
  }

  Future load(dynamic image) async {
    loader = Completer<bool>();

    if (image is ImageItem) {
      bytes = image.bytes;

      height = image.height;
      width = image.width;

      return loader.complete(true);
    } else if (image is Uint8List) {
      bytes = image;
      var decodedImage = await decodeImageFromList(bytes);

      height = decodedImage.height;
      width = decodedImage.width;

      if (height < width) {
        final exifData = await readExifFromBytes(bytes);

        img.Image fixedImage;

        if (height < width) {
          debugPrint('Rotating image necessary');
          final originalImage = img.decodeImage(bytes)!;
          if (exifData['Image Orientation']!.printable.contains('Horizontal')) {
            fixedImage = img.copyRotate(originalImage, angle: 90);
          } else if (exifData['Image Orientation']!.printable.contains('180')) {
            fixedImage = img.copyRotate(originalImage, angle: -90);
          } else if (exifData['Image Orientation']!.printable.contains('CCW')) {
            fixedImage = img.copyRotate(originalImage, angle: 180);
          } else {
            fixedImage = img.copyRotate(originalImage, angle: 0);
          }
          bytes = img.encodeJpg(fixedImage);
          height = fixedImage.height;
          width = fixedImage.width;
        }
      }

      return loader.complete(true);
    } else {
      return loader.complete(false);
    }
  }
}
