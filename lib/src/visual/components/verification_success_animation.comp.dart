import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:vector_graphics/vector_graphics.dart';

/// Animated chain-link logo for the "verification success" moment.
///
/// Sequence:
/// 1. Two chain links fly in from opposite sides with a bounce.
/// 2. Colour shifts from muted grey to the brand success-green.
/// 3. A scale-pulse + expanding ripple rings signal the connection.
/// 4. Sparkle particles radiate outward.
/// 5. A secure-checkmark badge pops in at the centre.
class VerificationSuccessAnimation extends StatefulWidget {
  const VerificationSuccessAnimation({
    super.key,
    this.size = 200,
    this.onComplete,
    this.autoStart = true,
  });

  /// Logical size of the animation widget (width = height).
  final double size;

  /// Called once the full sequence finishes.
  final VoidCallback? onComplete;

  /// When `true` the animation begins automatically after the first frame.
  final bool autoStart;

  @override
  State<VerificationSuccessAnimation> createState() =>
      VerificationSuccessAnimationState();
}

class VerificationSuccessAnimationState
    extends State<VerificationSuccessAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _idleCtrl;
  late final Animation<double> _flyIn;
  late final Animation<double> _colorFade;
  late final Animation<double> _pulse;
  late final Animation<double> _glow;
  late final Animation<double> _ripple;
  late final Animation<double> _sparkle;
  late final Animation<double> _badge;
  late final Animation<double> _idleBadgeScale;
  late final Animation<double> _chainsFade;
  bool _hapticTriggered = false;

  // Upper-right chain link
  static const _path1 =
      'M451.5 160C434.9 160 418.8 164.5 404.7 172.7C388.9 156.7 '
      '370.5 143.3 350.2 133.2C378.4 109.2 414.3 96 451.5 96C537.9 '
      '96 608 166 608 252.5C608 294 591.5 333.8 562.2 363.1L491.1 '
      '434.2C461.8 463.5 422 480 380.5 480C294.1 480 224 410 224 '
      '323.5C224 322 224 320.5 224.1 319C224.6 301.3 239.3 287.4 257 '
      '287.9C274.7 288.4 288.6 303.1 288.1 320.8C288.1 321.7 288.1 '
      '322.6 288.1 323.4C288.1 374.5 329.5 415.9 380.6 415.9C405.1 '
      '415.9 428.6 406.2 446 388.8L517.1 317.7C534.4 300.4 544.2 '
      '276.8 544.2 252.3C544.2 201.2 502.8 159.8 451.7 159.8z';

  // Lower-left chain link
  static const _path2 =
      'M307.2 237.3C305.3 236.5 303.4 235.4 301.7 234.2C289.1 '
      '227.7 274.7 224 259.6 224C235.1 224 211.6 233.7 194.2 '
      '251.1L123.1 322.2C105.8 339.5 96 363.1 96 387.6C96 438.7 '
      '137.4 480.1 188.5 480.1C205 480.1 221.1 475.7 235.2 '
      '467.5C251 483.5 269.4 496.9 289.8 507C261.6 530.9 225.8 '
      '544.2 188.5 544.2C102.1 544.2 32 474.2 32 387.7C32 346.2 '
      '48.5 306.4 77.8 277.1L148.9 206C178.2 176.7 218 160.2 259.5 '
      '160.2C346.1 160.2 416 230.8 416 317.1C416 318.4 416 319.7 '
      '416 321C415.6 338.7 400.9 352.6 383.2 352.2C365.5 351.8 '
      '351.6 337.1 352 319.4C352 318.6 352 317.9 352 317.1C352 '
      '283.4 334 253.8 307.2 237.5z';

  // Pre-built SVG markup (white fill – colour applied via ColorFilter
  // so flutter_svg can cache the parsed picture).
  static const _svg1 =
      '<svg viewBox="0 0 640 640"><path d="$_path1" fill="white"/></svg>';
  static const _svg2 =
      '<svg viewBox="0 0 640 640"><path d="$_path2" fill="white"/></svg>';

  static const _grey = Color(0xFF8E9AAF);
  static const Color _green = primaryColor;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );

    // Continuous idle pulse for the badge (makes it feel alive)
    _idleCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);

    _idleBadgeScale =
        Tween<double>(
          begin: 0.99,
          end: 1.01,
        ).animate(
          CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOut),
        );

    // Stage 1 – links fly in with a satisfying bounce
    _flyIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.38, curve: _SmoothBounceCurve()),
    );

    // Stage 2 – colour shift grey → green
    _colorFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.42, curve: Curves.easeInOut),
    );

    // Ambient glow ramps up around connection
    _glow = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 0.50, curve: Curves.easeIn),
    );

    // Scale-pulse on impact
    _pulse = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.34, 0.46, curve: Curves.easeInOut),
    );

    // Expanding ripple rings
    _ripple = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.36, 0.62, curve: Curves.easeOut),
    );

    // Sparkle particles
    _sparkle = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.38, 0.68, curve: Curves.easeOut),
    );

    // Verification badge
    _badge = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.44, 0.74, curve: Curves.elasticOut),
    );

    // Monotonic fade out for the chains, aligned with badge appearance
    _chainsFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.44, 0.56, curve: Curves.easeOut),
    );

    _ctrl
      ..addListener(() {
        if (_ctrl.value >= 0.44 && !_hapticTriggered) {
          _hapticTriggered = true;
          HapticFeedback.successNotification();
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => play());
    }
  }

  /// Start (or replay) the full animation from the beginning.
  void play() {
    _hapticTriggered = false;
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _idleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ctrl, _idleCtrl]),
      builder: (context, _) {
        final scale = widget.size / 640;
        final t = _flyIn.value; // 0 → 1 (fly-in progress)
        final sep = 1.0 - t; // 1 → 0 (separation)

        // Fly-in: upper-right link arrives from upper-right corner,
        // lower-left link arrives from lower-left corner.
        final dx = sep * 100 * scale;
        final dy = sep * -60 * scale;

        // Fly-in rotation: each link starts rotated ~50° from its
        // interlocked position so they visually thread into each other.
        final rotation = sep * 0.7;

        // Interpolated colour.
        final color = Color.lerp(_grey, _green, _colorFade.value)!;

        // Pulse: 1 → 1.08 → 1 (smooth sine bump).
        final pulseScale = 1.0 + math.sin(_pulse.value * math.pi) * 0.08;

        // Chains fade out as badge appears (monotonic to avoid springy pop-in glitches).
        final chainsOpacity = 1.0 - _chainsFade.value;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: [
              // ── Ambient glow ──
              if (_glow.value > 0)
                Center(
                  child: Container(
                    width: widget.size * 0.5,
                    height: widget.size * 0.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.3 * _glow.value),
                          blurRadius: widget.size * 0.45 * _glow.value,
                          spreadRadius: widget.size * 0.08 * _glow.value,
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Ripple rings ──
              if (_ripple.value > 0)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RipplePainter(
                      progress: _ripple.value,
                      color: _green,
                      maxRadius: widget.size * 0.45,
                    ),
                  ),
                ),

              // ── Chain links ──
              if (chainsOpacity > 0)
                Center(
                  child: Opacity(
                    opacity: chainsOpacity,
                    child: Transform.scale(
                      scale: pulseScale,
                      child: SizedBox(
                        width: widget.size,
                        height: widget.size,
                        child: Stack(
                          children: [
                            // Upper-right link — pivots around (416, 288) in
                            // the 640×640 viewport, matching link_logo_animation.
                            Positioned.fill(
                              child: Transform(
                                alignment: const Alignment(
                                  (416 * 2 / 640) - 1, // ≈ 0.3
                                  (288 * 2 / 640) - 1, // ≈ -0.1
                                ),
                                transform: Matrix4.identity()
                                  ..translateByDouble(dx, dy, 0, 1)
                                  ..rotateZ(-rotation),
                                child: Opacity(
                                  opacity: (0.35 + 0.65 * t).clamp(0.0, 1.0),
                                  child: SvgPicture.string(
                                    _svg1,
                                    colorFilter: ColorFilter.mode(
                                      color,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Lower-left link — pivots around (224, 352).
                            Positioned.fill(
                              child: Transform(
                                alignment: const Alignment(
                                  (224 * 2 / 640) - 1, // ≈ -0.3
                                  (352 * 2 / 640) - 1, // ≈  0.1
                                ),
                                transform: Matrix4.identity()
                                  ..translateByDouble(-dx, -dy, 0, 1)
                                  ..rotateZ(-rotation),
                                child: Opacity(
                                  opacity: (0.35 + 0.65 * t).clamp(0.0, 1.0),
                                  child: SvgPicture.string(
                                    _svg2,
                                    colorFilter: ColorFilter.mode(
                                      color,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Sparkle particles ──
              if (_sparkle.value > 0)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SparklePainter(
                      progress: _sparkle.value,
                      color: _green,
                      maxRadius: widget.size * 0.4,
                    ),
                  ),
                ),

              // ── Verification badge ──
              if (_badge.value > 0)
                Center(
                  child: Transform.scale(
                    scale: _badge.value * _idleBadgeScale.value,
                    child: Opacity(
                      opacity: _badge.value.clamp(0.0, 1.0),
                      child: SizedBox(
                        width: widget.size * 0.5,
                        height: widget.size * 0.5,
                        child: const SvgPicture(
                          AssetBytesLoader(
                            'assets/icons/verified_badge_green.svg.vec',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A custom curve that simulates a smooth, organic spring/bounce overshoot.
/// It overshoots, returns, and settles without any sharp direction changes.
class _SmoothBounceCurve extends Curve {
  const _SmoothBounceCurve();

  @override
  double transformInternal(double t) {
    // Damped harmonic oscillator equation: 1 - e^(-6*t) * cos(2.5 * pi * t)
    // Starts exactly at 0.0 (t=0) and ends exactly at 1.0 (t=1).
    return 1.0 - math.exp(-6.0 * t) * math.cos(2.5 * math.pi * t);
  }
}

/// Draws 3 staggered, concentric ring outlines that expand and fade out.
class _RipplePainter extends CustomPainter {
  const _RipplePainter({
    required this.progress,
    required this.color,
    required this.maxRadius,
  });

  final double progress;
  final Color color;
  final double maxRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var i = 0; i < 3; i++) {
      final delay = i * 0.15;
      final p = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (p <= 0) continue;

      final radius = p * maxRadius;
      final opacity = (1.0 - p) * 0.35;
      if (opacity <= 0) continue;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - p) + 0.5,
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}

/// Draws 12 small dots that radiate outward from the centre and fade away.
class _SparklePainter extends CustomPainter {
  const _SparklePainter({
    required this.progress,
    required this.color,
    required this.maxRadius,
  });

  final double progress;
  final Color color;
  final double maxRadius;

  static const _outerCount = 8;
  static const _innerCount = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Outer ring — 8 larger dots
    for (var i = 0; i < _outerCount; i++) {
      _drawDot(
        canvas,
        center,
        angle: (i / _outerCount) * 2 * math.pi + math.pi / 8,
        radius: progress * maxRadius,
        opacity: (1.0 - progress) * 0.7,
        dotSize: (1.0 - progress) * 3.0 + 0.8,
      );
    }

    // Inner ring — 8 smaller dots, offset angle, shorter travel
    final innerProgress = (progress * 1.15).clamp(0.0, 1.0);
    for (var i = 0; i < _innerCount; i++) {
      _drawDot(
        canvas,
        center,
        angle: (i / _innerCount) * 2 * math.pi,
        radius: innerProgress * maxRadius * 0.6,
        opacity: (1.0 - innerProgress) * 0.5,
        dotSize: (1.0 - innerProgress) * 2.0 + 0.5,
      );
    }
  }

  void _drawDot(
    Canvas canvas,
    Offset center, {
    required double angle,
    required double radius,
    required double opacity,
    required double dotSize,
  }) {
    if (opacity <= 0) return;
    canvas.drawCircle(
      Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      ),
      dotSize,
      Paint()..color = color.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.progress != progress;
}
