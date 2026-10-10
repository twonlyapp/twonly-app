import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/helpers/memory_map.helper.dart';

MemoryMapPoint point(
  double latitude,
  double longitude, [
  String id = 'photo',
]) => MemoryMapPoint(mediaId: id, latitude: latitude, longitude: longitude);

void main() {
  test(
    'starts at the most populated area, rather than the worldwide center',
    () {
      final camera = mostPopulatedMemoryCamera([
        point(40.7, -74),
        point(51.5, -0.1),
        for (var i = 0; i < 20; i++) point(52.52 + i * 0.001, 13.405),
      ]);
      expect(camera.target.latitude, closeTo(52.5295, 0.001));
      expect(camera.target.longitude, closeTo(13.405, 0.001));
      expect(camera.zoom, greaterThan(10));
    },
  );

  test('adjacent cells and date line locations remain one neighborhood', () {
    final camera = mostPopulatedMemoryCamera([
      point(0, 179.99),
      point(0, -179.99),
      point(0.01, 180),
      point(52, 13),
    ]);
    expect(camera.target.longitude.abs(), closeTo(180, 0.01));
    expect(camera.target.latitude, closeTo(0.0033, 0.001));
  });

  test('single and colocated images have a useful capped initial zoom', () {
    for (final points in [
      [point(0, 0)],
      [point(0, 0), point(0, 0)],
    ]) {
      final camera = mostPopulatedMemoryCamera(points);
      expect(camera.target.latitude, closeTo(0, 0.000001));
      expect(camera.target.longitude, 0);
      expect(camera.zoom, 14);
    }
  });

  test(
    'initial camera ignores invalid coordinates and clamps polar projection',
    () {
      final camera = mostPopulatedMemoryCamera([
        point(double.nan, 10),
        point(52, double.infinity),
        point(91, 13),
        point(90, 0),
      ]);
      expect(camera.target.latitude, closeTo(85.05112878, 0.00001));
      expect(camera.zoom.isFinite, isTrue);
      expect(mostPopulatedMemoryCamera([]).zoom, 2);
    },
  );

  test(
    'viewport includes edge points and excludes out of bounds coordinates',
    () {
      bool contains(MemoryMapPoint p) => memoryMapContains(
        p,
        south: 50,
        north: 54,
        west: 10,
        east: 16,
      );
      expect(contains(point(52, 13)), isTrue);
      expect(contains(point(50, 10)), isTrue);
      expect(contains(point(54, 16)), isTrue);
      expect(contains(point(55, 13)), isFalse);
      expect(contains(point(52, 17)), isFalse);
      expect(contains(point(double.nan, 13)), isFalse);
    },
  );

  test('viewport handles the date line and repeated world copies', () {
    bool contains(double longitude, double west, double east) =>
        memoryMapContains(
          point(0, longitude),
          south: -10,
          north: 10,
          west: west,
          east: east,
        );
    expect(contains(179, 170, -170), isTrue);
    expect(contains(-179, 170, -170), isTrue);
    expect(contains(0, 170, -170), isFalse);
    expect(contains(-175, 170, 190), isTrue);
    expect(contains(10, -180, 180), isTrue);
    expect(contains(-179, 180, 540), isTrue);
  });

  test('GeoJSON preserves photo identity and uses longitude first', () {
    final json = memoryMapGeoJson([point(52, 13, 'berlin'), point(91, 13)]);
    final features = json['features']! as List;
    expect(features, hasLength(1));
    expect(features.single, {
      'type': 'Feature',
      'id': 'berlin',
      'properties': {'mediaId': 'berlin'},
      'geometry': {
        'type': 'Point',
        'coordinates': [13.0, 52.0],
      },
    });
  });
}
