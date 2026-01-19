import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

abstract class FaceFilterPainter extends CustomPainter {
  FaceFilterPainter(
    this.faces,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
  );

  final List<Face> faces;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  @override
  bool shouldRepaint(covariant FaceFilterPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.faces != faces ||
        oldDelegate.rotation != rotation ||
        oldDelegate.cameraLensDirection != cameraLensDirection;
  }
}

class Preview extends StatelessWidget {
  const Preview({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withValues(alpha: 0.2),
      ),
      child: Center(
        child: child,
      ),
    );
  }
}
