import 'package:flutter/material.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/visual/components/location_card.dart';
import 'package:twonly/src/visual/views/chats/live_location_map.view.dart';

/// Draws the location filter's map where the sender placed it. The map is not
/// part of the media's pixels, only its coordinates and rectangle are sent.
class PhotoLocationOverlay extends StatelessWidget {
  const PhotoLocationOverlay({
    required this.location,
    required this.mediaAspectRatio,
    super.key,
  });

  final PhotoLocationData location;

  /// Width over height of the media, which is shown contained and centered.
  final double mediaAspectRatio;

  static PhotoLocationData? decode(List<int>? bytes) {
    if (bytes == null) return null;
    try {
      final data = AdditionalMessageData.fromBuffer(bytes);
      if (!data.hasPhotoLocation()) return null;
      final location = data.photoLocation;
      bool fraction(double value) => value.isFinite && value >= 0 && value <= 1;
      if (!location.latitude.isFinite ||
          !location.longitude.isFinite ||
          location.latitude.abs() > 90 ||
          location.longitude.abs() > 180 ||
          !fraction(location.mapLeft) ||
          !fraction(location.mapTop) ||
          !fraction(location.mapWidth) ||
          !fraction(location.mapHeight) ||
          location.mapWidth == 0 ||
          location.mapHeight == 0) {
        return null;
      }
      return location;
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final box = constraints.biggest;
      if (!box.isFinite || box.isEmpty || !(mediaAspectRatio > 0)) {
        return const SizedBox.shrink();
      }
      final media = box.width / box.height > mediaAspectRatio
          ? Size(box.height * mediaAspectRatio, box.height)
          : Size(box.width, box.width / mediaAspectRatio);
      final left = (box.width - media.width) / 2;
      final top = (box.height - media.height) / 2;
      final size = Size(
        location.mapWidth * media.width,
        location.mapHeight * media.height,
      );
      return Stack(
        children: [
          Positioned(
            left: left + location.mapLeft * media.width,
            top: top + location.mapTop * media.height,
            child: GestureDetector(
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoLocationMapView(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    fixTimestampMs: location.hasFixTimestampMs()
                        ? location.fixTimestampMs.toInt()
                        : null,
                  ),
                ),
              ),
              child: LocationCard(
                latitude: location.latitude,
                longitude: location.longitude,
                size: size,
              ),
            ),
          ),
        ],
      );
    },
  );
}
