import 'package:flutter/material.dart';
import 'package:hand_signature/signature.dart';
// ignore: implementation_imports
import 'package:hand_signature/src/utils.dart';

class CustomHandSignature extends StatelessWidget {
  const CustomHandSignature({
    required this.control,
    required this.isModificationEnabled,
    required this.currentColor,
    required this.width,
    super.key,
  });

  /// The controller that manages the creation and manipulation of signature paths.
  final HandSignatureControl control;
  final bool isModificationEnabled;
  final Color currentColor;
  final double width;

  @override
  Widget build(BuildContext context) {
    control.params = SignaturePaintParams(
      color: currentColor,
      strokeWidth: 7,
    );

    final drawer = CustomSignatureDrawer(color: currentColor, width: width);

    if (isModificationEnabled) {
      return HandSignature(
        control: control,
        drawer: drawer,
      );
    }

    return IgnorePointer(
      child: ClipRRect(
        child: HandSignaturePaint(
          control: control,
          drawer: drawer,
          onSize: control.notifyDimension,
        ),
      ),
    );
  }
}

class CustomSignatureDrawer extends HandSignatureDrawer {
  const CustomSignatureDrawer({
    this.width = 1.0,
    this.color = Colors.black,
  });
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size, List<CubicPath> paths) {
    for (final path in paths) {
      var lineColor = color;
      if (path.setup.args!['color'] != null) {
        lineColor = path.setup.args!['color'] as Color;
      } else {
        path.setup.args!['color'] = color;
      }
      final paint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width;
      if (path.isFilled) {
        canvas.drawPath(PathUtil.toLinePath(path.lines), paint);
      }
    }
  }
}
