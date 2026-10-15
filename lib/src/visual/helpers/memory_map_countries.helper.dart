import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

Future<List<MemoryMapCountry>>? _countries;

/// Decode once, away from the UI thread. Photo coordinates stay on device.
Future<List<MemoryMapCountry>> loadMemoryMapCountries() =>
    _countries ??= rootBundle
        .load('assets/maps/countries.json.gz')
        .then(
          (data) => compute(
            _decodeCountries,
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          ),
        );

List<MemoryMapCountry> _decodeCountries(Uint8List bytes) {
  final data =
      jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>;
  final scale = data['scale'] as num;
  return (data['countries'] as List).map((dynamic entry) {
    final country = entry as List;
    final polygons = (country[1] as List).map((dynamic polygon) {
      final rings = (polygon as List).map((dynamic values) {
        final deltas = values as List;
        var longitude = 0;
        var latitude = 0;
        return [
          for (var index = 0; index < deltas.length; index += 2)
            LatLng(
              (latitude += deltas[index + 1] as int) / scale,
              (longitude += deltas[index] as int) / scale,
            ),
        ];
      }).toList();
      return _CountryPolygon(rings);
    }).toList();
    return MemoryMapCountry._(country[0] as String, polygons);
  }).toList();
}

class MemoryMapCountry {
  MemoryMapCountry._(this.code, this._polygons) {
    south = _polygons.map((p) => p.south).reduce(math.min);
    north = _polygons.map((p) => p.north).reduce(math.max);
    west = _polygons.map((p) => p.west).reduce(math.min);
    east = _polygons.map((p) => p.east).reduce(math.max);
  }

  final String code;
  final List<_CountryPolygon> _polygons;
  late final double south;
  late final double north;
  late final double west;
  late final double east;

  Iterable<LatLng> get outline => _polygons.expand((p) => p.rings.first);

  bool contains(double latitude, double longitude) =>
      latitude >= south &&
      latitude <= north &&
      longitude >= west &&
      longitude <= east &&
      _polygons.any((p) => p.contains(latitude, longitude));
}

class _CountryPolygon {
  _CountryPolygon(this.rings) {
    final outer = rings.first;
    south = outer.map((p) => p.latitude).reduce(math.min);
    north = outer.map((p) => p.latitude).reduce(math.max);
    west = outer.map((p) => p.longitude).reduce(math.min);
    east = outer.map((p) => p.longitude).reduce(math.max);
  }

  final List<List<LatLng>> rings;
  late final double south;
  late final double north;
  late final double west;
  late final double east;

  bool contains(double latitude, double longitude) =>
      latitude >= south &&
      latitude <= north &&
      longitude >= west &&
      longitude <= east &&
      _inRing(rings.first, latitude, longitude) &&
      !rings.skip(1).any((ring) => _inRing(ring, latitude, longitude));
}

bool _inRing(List<LatLng> ring, double latitude, double longitude) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i];
    final b = ring[j];
    if ((a.latitude > latitude) != (b.latitude > latitude) &&
        longitude <
            (b.longitude - a.longitude) *
                    (latitude - a.latitude) /
                    (b.latitude - a.latitude) +
                a.longitude) {
      inside = !inside;
    }
  }
  return inside;
}
