import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/views/camera/painters/coordinates_translator.dart';
import 'package:twonly/src/views/camera/painters/face_filters/face_filter_painter.dart';

class BeardFilterPainter extends FaceFilterPainter {
  BeardFilterPainter(
    super.faces,
    super.imageSize,
    super.rotation,
    super.cameraLensDirection,
  ) {
    _loadAssets();
  }

  static ui.Image? _beardImage;
  static bool _loading = false;

  static Future<void> _loadAssets() async {
    if (_loading || _beardImage != null) return;
    _loading = true;
    try {
      _beardImage = await _loadImage('assets/filters/beard_upper_lip.webp');
    } catch (e) {
      Log.error('Failed to load filter assets: $e');
    } finally {
      _loading = false;
    }
  }

  static Future<ui.Image> _loadImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final list = Uint8List.view(data.buffer);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(list, completer.complete);
    return completer.future;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_beardImage == null) return;

    for (final face in faces) {
      final noseBase = face.landmarks[FaceLandmarkType.noseBase];
      final mouthLeft = face.landmarks[FaceLandmarkType.leftMouth];
      final mouthRight = face.landmarks[FaceLandmarkType.rightMouth];
      final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];

      if (noseBase != null &&
          mouthLeft != null &&
          mouthRight != null &&
          bottomMouth != null) {
        final noseX = translateX(
          noseBase.position.x.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );
        final noseY = translateY(
          noseBase.position.y.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );

        final mouthLeftX = translateX(
          mouthLeft.position.x.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );
        final mouthLeftY = translateY(
          mouthLeft.position.y.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );

        final mouthRightX = translateX(
          mouthRight.position.x.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );
        final mouthRightY = translateY(
          mouthRight.position.y.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );

        final mouthCenterX = (mouthLeftX + mouthRightX) / 2;
        final mouthCenterY = (mouthLeftY + mouthRightY) / 2;

        final beardCenterX = (noseX + mouthCenterX) / 2;
        final beardCenterY = (noseY + mouthCenterY) / 2;

        final dx = mouthRightX - mouthLeftX;
        final dy = mouthRightY - mouthLeftY;
        final angle = atan2(dy, dx);

        final mouthWidth = sqrt(dx * dx + dy * dy);
        final beardWidth = mouthWidth * 1.5;

        final yaw = face.headEulerAngleY ?? 0;
        final scaleX = cos(yaw * pi / 180).abs();

        _drawImage(
          canvas,
          _beardImage!,
          Offset(beardCenterX, beardCenterY),
          beardWidth,
          angle,
          scaleX,
        );
      }
    }
  }

  void _drawImage(
    Canvas canvas,
    ui.Image image,
    Offset position,
    double width,
    double rotation,
    double scaleX,
  ) {
    canvas
      ..save()
      ..translate(position.dx, position.dy)
      ..rotate(rotation)
      ..scale(scaleX, Platform.isAndroid ? -1 : 1);

    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    final aspectRatio = image.width / image.height;
    final dstWidth = width;
    final dstHeight = width / aspectRatio;

    final dstRect = Rect.fromCenter(
      center: Offset.zero,
      width: dstWidth,
      height: dstHeight,
    );

    canvas
      ..drawImageRect(image, srcRect, dstRect, Paint())
      ..restore();
  }

  static Widget getPreview() {
    return Preview(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          'assets/filters/beard_upper_lip.webp',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
