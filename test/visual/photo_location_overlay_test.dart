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
