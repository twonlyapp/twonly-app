import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as io;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:twonly/src/utils/log.dart';

class ScreenshotImage {
  ScreenshotImage({
    this.image,
    this.imageBytes,
    this.imageBytesFuture,
    this.file,
  });

  io.Image? image;
  Uint8List? imageBytes;
  Future<Uint8List>? imageBytesFuture;
  File? file;

  Future<Uint8List?> getBytes() async {
    if (imageBytes != null) {
      return imageBytes;
    }
    if (imageBytesFuture != null) {
      return imageBytesFuture;
    }
    if (file != null) {
      return file!.readAsBytes();
    }
    if (image == null) return null;
    final img = await image!.toByteData(format: io.ImageByteFormat.png);
    if (img == null) {
      Log.error('Got no image');
      return null;
    }
    return imageBytes = img.buffer.asUint8List();
  }
}

class ScreenshotController {
  ScreenshotController() {
    _containerKey = GlobalKey();
  }
  late GlobalKey _containerKey;

  Future<ScreenshotImage?> capture({double? pixelRatio}) async {
    try {
      final findRenderObject = _containerKey.currentContext?.findRenderObject();
      if (findRenderObject == null) {
        return null;
      }
      final boundary = findRenderObject as RenderRepaintBoundary;
      final context = _containerKey.currentContext;
      var tmpPixelRatio = pixelRatio;
      if (tmpPixelRatio == null) {
        if (context != null && context.mounted) {
          tmpPixelRatio =
              tmpPixelRatio ?? MediaQuery.of(context).devicePixelRatio;
        }
      }
      final image = await boundary.toImage(pixelRatio: tmpPixelRatio ?? 1);
      return ScreenshotImage(image: image);
    } catch (e) {
      Log.error(e);
    }
    return null;
  }
}

class Screenshot extends StatefulWidget {
  const Screenshot({
    required this.child,
    required this.controller,
    super.key,
  });
  final Widget? child;
  final ScreenshotController controller;

  @override
  State<Screenshot> createState() {
    return ScreenshotState();
  }
}

class ScreenshotState extends State<Screenshot> with TickerProviderStateMixin {
  late ScreenshotController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _controller._containerKey,
      child: widget.child,
    );
  }
}
