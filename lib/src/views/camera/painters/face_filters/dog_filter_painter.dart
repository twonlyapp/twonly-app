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

class DogFilterPainter extends FaceFilterPainter {
  DogFilterPainter(
    super.faces,
    super.imageSize,
    super.rotation,
    super.cameraLensDirection,
  ) {
    _loadAssets();
  }

  static ui.Image? _earImage;
  static ui.Image? _noseImage;
  static bool _loading = false;

  static Future<void> _loadAssets() async {
    if (_loading || (_earImage != null && _noseImage != null)) return;
    _loading = true;
    try {
      _earImage = await _loadImage('assets/filters/dog_brown_ear.webp');
      _noseImage = await _loadImage('assets/filters/dog_brown_nose.webp');
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
    if (_earImage == null || _noseImage == null) return;

    for (final face in faces) {
      final faceContour = face.contours[FaceContourType.face];
      final noseBase = face.landmarks[FaceLandmarkType.noseBase];

      if (faceContour != null && noseBase != null) {
        final points = faceContour.points;
        if (points.isEmpty) continue;

        final upperPoints =
            points.where((p) => p.y < noseBase.position.y).toList();

        if (upperPoints.isEmpty) continue;

        Point<int>? leftMost;
        Point<int>? rightMost;
        Point<int>? topMost;

        for (final point in upperPoints) {
          if (leftMost == null || point.x < leftMost.x) {
            leftMost = point;
          }
          if (rightMost == null || point.x > rightMost.x) {
            rightMost = point;
          }
          if (topMost == null || point.y < topMost.y) {
            topMost = point;
          }
        }

        if (leftMost == null || rightMost == null || topMost == null) continue;

        final leftEarX = translateX(
          leftMost.x.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );
        final leftEarY = translateY(
          topMost.y.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );

        final rightEarX = translateX(
          rightMost.x.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );
        final rightEarY = translateY(
          topMost.y.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );

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

        final dx = rightEarX - leftEarX;
        final dy = rightEarY - leftEarY;

        final faceWidth = sqrt(dx * dx + dy * dy) * 1.5;
        final angle = atan2(dy, dx);

        final yaw = face.headEulerAngleY ?? 0;
        final scaleX = cos(yaw * pi / 180).abs();

        final earSize = faceWidth / 2.5;

        _drawImage(
          canvas,
          _earImage!,
          Offset(leftEarX, leftEarY + earSize * 0.3),
          earSize,
          angle,
          scaleX,
        );

        _drawImage(
          canvas,
          _earImage!,
          Offset(rightEarX, rightEarY + earSize * 0.3),
          earSize,
          angle,
          scaleX,
          isFlipped: true,
        );

        final noseSize = faceWidth * 0.4;
        _drawImage(
          canvas,
          _noseImage!,
          Offset(noseX, noseY + noseSize * 0.1),
          noseSize,
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
    double size,
    double rotation,
    double scaleX, {
    bool isFlipped = false,
  }) {
    canvas
      ..save()
      ..translate(position.dx, position.dy)
      ..rotate(rotation);
    if (isFlipped) {
      canvas.scale(-scaleX, Platform.isAndroid ? -1 : 1);
    } else {
      canvas.scale(scaleX, Platform.isAndroid ? -1 : 1);
    }

    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final aspectRatio = image.width / image.height;
    final dstWidth = size;
    final dstHeight = size / aspectRatio;

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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 25),
            child: Image.asset(
              'assets/filters/dog_brown_nose.webp',
              width: 25,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/filters/dog_brown_ear.webp',
                  width: 20,
                ),
                const SizedBox(width: 15),
                Transform.scale(
                  scaleX: -1,
                  child: Image.asset(
                    'assets/filters/dog_brown_ear.webp',
                    width: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
