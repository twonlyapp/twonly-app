import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class CustomColorPickerDialog extends StatefulWidget {
  const CustomColorPickerDialog({
    required this.initialColor,
    super.key,
  });

  final Color initialColor;

  @override
  State<CustomColorPickerDialog> createState() =>
      _CustomColorPickerDialogState();
}

class _CustomColorPickerDialogState extends State<CustomColorPickerDialog> {
  late HSVColor _hsvColor;

  @override
  void initState() {
    super.initState();
    final initialHsvColor = HSVColor.fromColor(widget.initialColor);
    final hasVisibleInitialColor =
        widget.initialColor.toARGB32() & 0xFF000000 != 0;
    _hsvColor =
        (hasVisibleInitialColor
                ? initialHsvColor
                : initialHsvColor.withValue(1))
            .withAlpha(1);
  }

  void _selectColor(Offset position, Size size) {
    const indicatorRadius = 12.0;
    final center = size.center(Offset.zero);
    final wheelRadius = size.shortestSide / 2 - indicatorRadius;
    final offset = position - center;
    final distance = offset.distance;
    final saturation = (distance / wheelRadius).clamp(0.0, 1.0);
    final hue = distance < 1
        ? _hsvColor.hue
        : (math.atan2(offset.dy, offset.dx) * 180 / math.pi + 360) % 360;

    setState(() {
      _hsvColor = HSVColor.fromAHSV(
        _hsvColor.alpha,
        hue,
        saturation,
        _hsvColor.value,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _hsvColor.toColor();
    final availableWidth = MediaQuery.sizeOf(context).width - 96;
    final wheelSize = math.max<double>(
      120,
      math.min<double>(240, availableWidth),
    );
    final colorWheelSize = Size.square(wheelSize);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(context.lang.customColor),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox.square(
                dimension: wheelSize,
                child: Semantics(
                  label: context.lang.customColor,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: (details) =>
                        _selectColor(details.localPosition, colorWheelSize),
                    onPanUpdate: (details) =>
                        _selectColor(details.localPosition, colorWheelSize),
                    onTapUp: (details) =>
                        _selectColor(details.localPosition, colorWheelSize),
                    child: CustomPaint(
                      painter: _ColorWheelPainter(hsvColor: _hsvColor),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: MyButton(
                variant: MyButtonVariant.text,
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.lang.cancel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MyButton(
                variant: MyButtonVariant.primaryMiddle,
                onPressed: () =>
                    Navigator.of(context).pop(currentColor.toARGB32()),
                child: Text(context.lang.ok),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  const _ColorWheelPainter({required this.hsvColor});

  final HSVColor hsvColor;

  static const _indicatorRadius = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - _indicatorRadius;
    final wheelRect = Rect.fromCircle(center: center, radius: radius);

    canvas
      ..save()
      ..clipPath(Path()..addOval(wheelRect))
      ..drawCircle(
        center,
        radius,
        Paint()
          ..shader = const SweepGradient(
            colors: [
              Color(0xFFFF0000),
              Color(0xFFFFFF00),
              Color(0xFF00FF00),
              Color(0xFF00FFFF),
              Color(0xFF0000FF),
              Color(0xFFFF00FF),
              Color(0xFFFF0000),
            ],
          ).createShader(wheelRect),
      )
      ..drawCircle(
        center,
        radius,
        Paint()
          ..shader = const RadialGradient(
            colors: [Colors.white, Colors.transparent],
          ).createShader(wheelRect),
      );

    if (hsvColor.value < 1) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = Colors.black.withValues(alpha: 1 - hsvColor.value),
      );
    }

    canvas.restore();

    final angle = hsvColor.hue * math.pi / 180;
    final indicatorCenter =
        center +
        Offset(math.cos(angle), math.sin(angle)) * hsvColor.saturation * radius;
    final selectedColor = hsvColor.withAlpha(1).toColor();

    canvas
      ..drawCircle(
        indicatorCenter,
        _indicatorRadius,
        Paint()..color = Colors.black.withValues(alpha: 0.3),
      )
      ..drawCircle(
        indicatorCenter,
        _indicatorRadius - 2,
        Paint()..color = Colors.white,
      )
      ..drawCircle(
        indicatorCenter,
        _indicatorRadius - 5,
        Paint()..color = selectedColor,
      );
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) =>
      oldDelegate.hsvColor != hsvColor;
}
