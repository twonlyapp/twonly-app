import 'dart:async';
import 'package:twonly/src/utils/screenshot.dart';

class ImageItem {
  ImageItem();
  int width = 1;
  int height = 1;
  ScreenshotImage? image;
  Completer<bool> loader = Completer<bool>();

  void load(ScreenshotImage img) {
    image = img;
    if (image?.image != null) {
      height = image!.image!.height;
      width = image!.image!.width;
    }
  }
}
