import 'dart:math';
import 'package:flutter/material.dart';

class SparksWidget extends StatefulWidget {
  const SparksWidget({
    required this.child,
    required this.animate,
    super.key,
  });

  final Widget child;
  final bool animate;

  @override
  State<SparksWidget> createState() => _SparksWidgetState();
}

class _SparksWidgetState extends State<SparksWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Spark> _sparks = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.animate) {
      _controller.repeat();
      _startSparksGenerator();
    }
  }

  @override
  void didUpdateWidget(SparksWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
        _startSparksGenerator();
      } else {
        _controller.stop();
        _sparks.clear();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startSparksGenerator() {
    _controller.addListener(_generateAndUpdateSparks);
  }

  void _generateAndUpdateSparks() {
    if (!mounted || !widget.animate) return;

    // Update existing sparks
    setState(() {
      _sparks.removeWhere((s) => s.progress >= 1.0);
      for (final spark in _sparks) {
        spark.progress += 0.005;
      }

      // Generate new spark occasionally
      if (_sparks.length < 15 && _random.nextDouble() < 0.15) {
        final angle = -pi * 0.58 + _random.nextDouble() * pi * 0.16;
        final speed = 60 + _random.nextDouble() * 60;
        final color = _random.nextBool()
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary;
        _sparks.add(
          Spark(
            angle: angle,
            speed: speed,
            color: color,
            size: 2 + _random.nextDouble() * 3,
            progress: 0,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return widget.child;
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          painter: SparksPainter(sparks: _sparks),
        ),
        widget.child,
      ],
    );
  }
}

class Spark {
  Spark({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.progress,
  });

  final double angle;
  final double speed;
  final Color color;
  final double size;
  double progress;
}

class SparksPainter extends CustomPainter {
  SparksPainter({required this.sparks});

  final List<Spark> sparks;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final spark in sparks) {
      final distance = spark.speed * spark.progress;
      final dx = cos(spark.angle) * distance;
      final dy = sin(spark.angle) * distance;

      final alpha = (220 * (1 - spark.progress)).toInt();
      paint.color = spark.color.withAlpha(alpha);

      canvas.drawCircle(Offset(dx, dy), spark.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SparksPainter oldDelegate) => true;
}
