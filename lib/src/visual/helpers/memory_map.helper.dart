import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:twonly/src/visual/helpers/memory_map_countries.helper.dart';

/// A point per distinct Memory, also used for viewport filtering when the
/// renderer has combined multiple points into a cluster.
class MemoryMapPoint {
  const MemoryMapPoint({
    required this.mediaId,
    required this.latitude,
    required this.longitude,
  });

  final String mediaId;
  final double latitude;
  final double longitude;

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  LatLng get coordinates => LatLng(latitude, longitude);

  Map<String, Object> get feature => {
    'type': 'Feature',
    'id': mediaId,
    'properties': {'mediaId': mediaId},
    'geometry': {
      'type': 'Point',
      'coordinates': [longitude, latitude],
    },
  };
}

Map<String, Object> memoryMapGeoJson(Iterable<MemoryMapPoint> points) => {
  'type': 'FeatureCollection',
  'features': points.where((p) => p.isValid).map((p) => p.feature).toList(),
};

/// Longitude bounds may cross the date line or cover multiple world copies.
bool memoryMapContains(
  MemoryMapPoint point, {
  required double south,
  required double north,
  required double west,
  required double east,
}) {
  if (!point.isValid || point.latitude < south || point.latitude > north) {
    return false;
  }
  if ((east - west).abs() >= 360) return true;
  final span = (east - west) % 360;
  return (point.longitude - west) % 360 <= span;
}

double _mercatorY(double latitude) {
  final radians = latitude.clamp(-85.05112878, 85.05112878) * math.pi / 180;
  return (1 - math.log(math.tan(math.pi / 4 + radians / 2)) / math.pi) / 2;
}

double _latitudeFromY(double y) {
  final n = math.pi * (1 - 2 * y);
  return math.atan((math.exp(n) - math.exp(-n)) / 2) * 180 / math.pi;
}

/// Frames the country with the most Memories. If no country can be identified
/// (for example, photos taken at sea), use the most populated neighborhood.
CameraPosition mostPopulatedMemoryCamera(
  Iterable<MemoryMapPoint> points, {
  List<MemoryMapCountry> countries = const [],
  double width = 350,
  double height = 350,
}) {
  final valid = points.where((p) => p.isValid).toList();
  if (countries.isNotEmpty) {
    final locations = <(double, double), MemoryMapCountry?>{};
    final counts = <MemoryMapCountry, int>{};
    for (final point in valid) {
      final country = locations.putIfAbsent(
        (point.latitude, point.longitude),
        () {
          for (final country in countries) {
            if (country.contains(point.latitude, point.longitude)) {
              return country;
            }
          }
          return null;
        },
      );
      if (country != null) {
        counts.update(country, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    MemoryMapCountry? winner;
    var bestCount = 0;
    // Insertion order breaks ties in favor of the most recent Memory.
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        bestCount = entry.value;
        winner = entry.key;
      }
    }
    if (winner != null) return _countryCamera(winner, width, height);
  }

  // A wrapped grid also keeps neighboring photos across the date line together.
  const cells = 8192;
  final grid = <(int, int), List<MemoryMapPoint>>{};
  for (final point in valid) {
    final x = (((point.longitude + 180) / 360 * cells).floor()) % cells;
    final y = (_mercatorY(point.latitude) * cells).floor().clamp(0, cells - 1);
    grid.putIfAbsent((x, y), () => []).add(point);
  }
  if (grid.isEmpty) {
    return const CameraPosition(target: LatLng(0, 0), zoom: 2);
  }

  // Include empty candidate cells: the densest neighborhood can be centered
  // between occupied cells. Insertion order breaks ties in favor of newer media.
  final candidates = <(int, int)>{};
  for (final cell in grid.keys) {
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        candidates.add(((cell.$1 + dx) % cells, cell.$2 + dy));
      }
    }
  }
  var bestCount = 0;
  var best = grid.keys.first;
  for (final cell in candidates) {
    var count = 0;
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        count += grid[((cell.$1 + dx) % cells, cell.$2 + dy)]?.length ?? 0;
      }
    }
    if (count > bestCount) {
      bestCount = count;
      best = cell;
    }
  }

  final neighborhood = <MemoryMapPoint>[];
  for (var dx = -1; dx <= 1; dx++) {
    for (var dy = -1; dy <= 1; dy++) {
      neighborhood.addAll(grid[((best.$1 + dx) % cells, best.$2 + dy)] ?? []);
    }
  }
  final reference = neighborhood.first.longitude;
  double xFor(MemoryMapPoint p) =>
      (reference + (p.longitude - reference + 180) % 360 - 180 + 180) / 360;
  final xs = neighborhood.map(xFor);
  final ys = neighborhood.map((p) => _mercatorY(p.latitude));
  final west = xs.reduce(math.min);
  final east = xs.reduce(math.max);
  final north = ys.reduce(math.min);
  final south = ys.reduce(math.max);
  final centerX = xs.reduce((a, b) => a + b) / neighborhood.length;
  final centerY = ys.reduce((a, b) => a + b) / neighborhood.length;

  // Fit the neighborhood around its weighted center, leaving room for markers.
  final spanX = 2 * math.max(centerX - west, east - centerX);
  final spanY = 2 * math.max(centerY - north, south - centerY);
  final scaleX = math.max(1, width - 80) / (512 * math.max(spanX, 0.000001));
  final scaleY = math.max(1, height - 80) / (512 * math.max(spanY, 0.000001));
  final zoom = (math.log(math.min(scaleX, scaleY)) / math.ln2).clamp(2.0, 14.0);
  return CameraPosition(
    target: LatLng(_latitudeFromY(centerY), (centerX * 360) % 360 - 180),
    zoom: zoom,
  );
}

CameraPosition _countryCamera(
  MemoryMapCountry country,
  double width,
  double height,
) {
  final xs =
      country.outline.map((p) => ((p.longitude + 180) % 360) / 360).toList()
        ..sort();
  // Remove the largest ocean gap so date-line countries such as Fiji are
  // framed together instead of spanning almost the entire world.
  var largestGap = -1.0;
  var west = xs.first;
  for (var index = 0; index < xs.length; index++) {
    final next = index + 1 < xs.length ? xs[index + 1] : xs.first + 1;
    final gap = next - xs[index];
    if (gap > largestGap) {
      largestGap = gap;
      west = next % 1;
    }
  }
  final spanX = 1 - largestGap;
  final north = _mercatorY(country.north);
  final south = _mercatorY(country.south);
  final scaleX = math.max(1, width - 80) / (512 * math.max(spanX, 0.000001));
  final scaleY =
      math.max(1, height - 80) / (512 * math.max(south - north, 0.000001));
  return CameraPosition(
    target: LatLng(
      _latitudeFromY((north + south) / 2),
      ((west + spanX / 2) * 360) % 360 - 180,
    ),
    zoom: (math.log(math.min(scaleX, scaleY)) / math.ln2).clamp(0.0, 14.0),
  );
}
