import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/photo_location_overlay.comp.dart';

List<int> _encode(PhotoLocationData location, {String? link}) =>
    AdditionalMessageData(
      type: link == null
          ? AdditionalMessageData_Type.PHOTO_LOCATION
          : AdditionalMessageData_Type.LINK,
      link: link,
      photoLocation: location,
    ).writeToBuffer();

PhotoLocationData _location() => PhotoLocationData(
  latitude: 52.52,
  longitude: 13.405,
  accuracy: 8.5,
  mapLeft: 0.2,
  mapTop: 0.6,
  mapWidth: 0.6,
  mapHeight: 0.2,
);

void main() {
  test('decodes a photo location, also beside a link', () {
    expect(PhotoLocationOverlay.decode(_encode(_location()))?.latitude, 52.52);
    expect(
      PhotoLocationOverlay.decode(
        _encode(_location(), link: 'https://twonly.eu'),
      )?.longitude,
      13.405,
    );
  });

  test('ignores data without a photo location', () {
    expect(PhotoLocationOverlay.decode(null), isNull);
    expect(PhotoLocationOverlay.decode([0xff, 0xff]), isNull);
    expect(
      PhotoLocationOverlay.decode(
        AdditionalMessageData(
          type: AdditionalMessageData_Type.LINK,
          link: 'https://twonly.eu',
        ).writeToBuffer(),
      ),
      isNull,
    );
  });

  test('hidden filters retain coordinates but do not draw an overlay', () {
    final bytes = _encode(_location()..hideFilter = true);
    final metadata = AdditionalMessageData.fromBuffer(bytes);
    expect(metadata.photoLocation.hideFilter, isTrue);
    expect(metadata.photoLocation.latitude, 52.52);
    expect(PhotoLocationOverlay.decode(bytes), isNull);
  });

  test('absent and explicit false hide flags keep the filter visible', () {
    for (final hideFilter in [null, false]) {
      final location = _location();
      if (hideFilter != null) location.hideFilter = hideFilter;
      final bytes = _encode(location);
      final decoded = AdditionalMessageData.fromBuffer(bytes).photoLocation;
      expect(decoded.hasHideFilter(), hideFilter != null);
      expect(decoded.hideFilter, isFalse);
      expect(PhotoLocationOverlay.decode(bytes), isNotNull);
    }
  });

  test('opening from the story map suppresses even a visible filter', () {
    final bytes = _encode(_location());
    expect(PhotoLocationOverlay.decode(bytes), isNotNull);
    expect(PhotoLocationOverlay.decode(bytes, fromMap: true), isNull);
    expect(
      AdditionalMessageData.fromBuffer(bytes).photoLocation.hideFilter,
      isFalse,
    );
  });

  test(
    'round-trips the edited viewport and scales it for the receiving card',
    () {
      final location = _location()
        ..mapLatitude = 53
        ..mapLongitude = 14
        ..mapZoom = 10;
      final decoded = PhotoLocationOverlay.decode(_encode(location))!;
      final camera = PhotoLocationOverlay.cameraPosition(decoded)!;
      expect(camera.target.latitude, 53);
      expect(camera.target.longitude, 14);
      expect(camera.zoom, 10);
      expect(PhotoLocationOverlay.cameraPosition(decoded, width: 130)!.zoom, 9);
      expect(
        PhotoLocationOverlay.cameraPosition(decoded, width: 520)!.zoom,
        11,
      );
      expect(PhotoLocationOverlay.cameraPosition(_location()), isNull);
      expect(decoded.latitude, 52.52);
      expect(decoded.longitude, 13.405);
    },
  );

  test('rejects incomplete or invalid map viewports', () {
    PhotoLocationData edited() => _location()
      ..mapLatitude = 53
      ..mapLongitude = 14
      ..mapZoom = 10;
    for (final location in [
      _location()..mapLatitude = 53,
      edited()..clearMapZoom(),
      edited()..mapLatitude = 91,
      edited()..mapLongitude = double.nan,
      edited()..mapZoom = double.infinity,
      edited()..mapZoom = -1,
      edited()..mapZoom = 23,
    ]) {
      expect(PhotoLocationOverlay.decode(_encode(location)), isNull);
    }
  });

  test('rejects coordinates or a map rectangle outside the media', () {
    for (final location in [
      _location()..latitude = 91,
      _location()..longitude = double.nan,
      _location()..mapLeft = -0.1,
      _location()..mapTop = 1.5,
      _location()..mapWidth = 0,
      _location()..mapHeight = double.infinity,
    ]) {
      expect(PhotoLocationOverlay.decode(_encode(location)), isNull);
    }
  });
}
