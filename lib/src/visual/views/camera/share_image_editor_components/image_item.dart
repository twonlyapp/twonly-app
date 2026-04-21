import 'dart:async';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';

class ImageItem {
  ImageItem();
  int width = 1;
  int height = 1;
  ScreenshotImageHelper? image;
  Completer<bool> loader = Completer<bool>();

  void load(ScreenshotImageHelper img) {
    image = img;
    if (image?.image != null) {
      height = image!.image!.height;
      width = image!.image!.width;
    }
  }
}
