import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:twonly/src/visual/helpers/memory_map_countries.helper.dart';

/// A small offline map of [points], drawn from the bundled country outlines
/// so the chat list needs neither a native map view nor tile requests.
///
/// [points] are ordered newest first; the newest is drawn on top.
class StoryMapPreview extends StatefulWidget {
  const StoryMapPreview({required this.points, this.size = 58, super.key});

  final List<LatLng> points;
  final double size;

  @override
  State<StoryMapPreview> createState() => _StoryMapPreviewState();
}

class _StoryMapPreviewState extends State<StoryMapPreview> {
  late final Future<List<MemoryMapCountry>> _countries =
      loadMemoryMapCountries();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: ClipOval(
        child: SizedBox.square(
          dimension: widget.size,
          child: FutureBuilder<List<MemoryMapCountry>>(
            future: _countries,
            builder: (context, snapshot) => CustomPaint(
              painter: _StoryMapPainter(
                countries: snapshot.data ?? const [],
                points: widget.points,
                // Close to the Positron and Fiord styles of the full map.
                water: dark ? const Color(0xff38435c) : const Color(0xffc8d3d6),
                land: dark ? const Color(0xff45516e) : const Color(0xfff4f4f1),
                border: dark
                    ? const Color(0xff5b6887)
                    : const Color(0xffd5d6d0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryMapPainter extends CustomPainter {
  _StoryMapPainter({
    required this.countries,
    required this.points,
    required this.water,
    required this.land,
    required this.border,
  });

  final List<MemoryMapCountry> countries;
  final List<LatLng> points;
  final Color water;
  final Color land;
  final Color border;

  /// The smallest visible span, as a fraction of the world's width: about
  /// 11 degrees of longitude, so a single story still shows its region.
  static const _minSpan = 0.03;

  static double _x(double longitude) => (longitude + 180) / 360;

  static double _y(double latitude) {
    final sin = math.sin(latitude.clamp(-85.0, 85.0) * math.pi / 180);
    return 0.5 - math.log((1 + sin) / (1 - sin)) / (4 * math.pi);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = water);

    var centerX = 0.5;
    var centerY = _y(20);
    var span = 1.0;
    if (points.isNotEmpty) {
      final xs = points.map((p) => _x(p.longitude));
      final ys = points.map((p) => _y(p.latitude));
      final west = xs.reduce(math.min);
      final east = xs.reduce(math.max);
      final north = ys.reduce(math.min);
      final south = ys.reduce(math.max);
      centerX = (west + east) / 2;
      centerY = (north + south) / 2;
      span = (math.max(east - west, south - north) * 1.6).clamp(_minSpan, 1.0);
    }
    final scale = size.shortestSide / span;
    final origin = size.center(Offset.zero);
    Offset project(double latitude, double longitude) =>
        origin +
        Offset(
          (_x(longitude) - centerX) * scale,
          (_y(latitude) - centerY) * scale,
        );

    final visible = Offset.zero & size;
    final landPaint = Paint()..color = land;
    final borderPaint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (final country in countries) {
      final bounds = Rect.fromPoints(
        project(country.north, country.west),
        project(country.south, country.east),
      );
      if (!bounds.overlaps(visible)) continue;
      final path = Path()..fillType = PathFillType.evenOdd;
      for (final polygon in country.polygons) {
        for (final ring in polygon) {
          Offset? last;
          double? previousLongitude;
          var wrap = 0.0;
          for (final point in ring) {
            // Keep rings crossing the antimeridian continuous instead of
            // drawing an edge across the whole world.
            if (previousLongitude != null) {
              final delta = point.longitude - previousLongitude;
              if (delta > 180) wrap -= 360;
              if (delta < -180) wrap += 360;
            }
            previousLongitude = point.longitude;
            final offset = project(point.latitude, point.longitude + wrap);
            if (last == null) {
              path.moveTo(offset.dx, offset.dy);
            } else if ((offset - last).distanceSquared >= 0.25) {
              path.lineTo(offset.dx, offset.dy);
            } else {
              continue;
            }
            last = offset;
          }
          path.close();
        }
      }
      canvas
        ..drawPath(path, landPaint)
        ..drawPath(path, borderPaint);
    }

    final dot = Paint()..color = const Color(0xff337eae);
    final halo = Paint()..color = const Color(0xffffffff);
    for (final point in points.reversed) {
      final offset = project(point.latitude, point.longitude);
      canvas
        ..drawCircle(offset, 5, halo)
        ..drawCircle(offset, 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_StoryMapPainter oldDelegate) =>
      !identical(countries, oldDelegate.countries) ||
      !listEquals(points, oldDelegate.points) ||
      water != oldDelegate.water ||
      land != oldDelegate.land ||
      border != oldDelegate.border;
}
