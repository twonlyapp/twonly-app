import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/visual/components/location_card.dart';

/// Draws the location filter's map where the sender placed it. The map is not
/// part of the media's pixels, only its coordinates and rectangle are sent.
/// Recipients start at the sender's viewport and can explore it independently.
class PhotoLocationOverlay extends StatelessWidget {
  const PhotoLocationOverlay({
    required this.location,
    required this.mediaAspectRatio,
    super.key,
  });

  final PhotoLocationData location;

  /// Width over height of the media, which is shown contained and centered.
  final double mediaAspectRatio;

  static PhotoLocationData? decode(List<int>? bytes, {bool fromMap = false}) {
    if (bytes == null || fromMap) return null;
    try {
      final data = AdditionalMessageData.fromBuffer(bytes);
      if (!data.hasPhotoLocation()) return null;
      final location = data.photoLocation;
      if (location.hideFilter) return null;
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
      if ((location.hasMapLatitude() ||
              location.hasMapLongitude() ||
              location.hasMapZoom()) &&
          cameraPosition(location) == null) {
        return null;
      }
      return location;
    } on Object {
      return null;
    }
  }

  /// Older messages use the location fix and default zoom. Adjust edited zoom
  /// for the receiving card's width so it shows the sender's visible area.
  static CameraPosition? cameraPosition(
    PhotoLocationData location, {
    double? width,
  }) {
    final cardWidth = width ?? locationCardSize.width;
    if (!location.hasMapLatitude() ||
        !location.hasMapLongitude() ||
        !location.hasMapZoom() ||
        !location.mapLatitude.isFinite ||
        !location.mapLongitude.isFinite ||
        location.mapLatitude.abs() > 90 ||
        location.mapLongitude.abs() > 180 ||
        !location.mapZoom.isFinite ||
        location.mapZoom < 0 ||
        location.mapZoom > 22 ||
        !cardWidth.isFinite ||
        cardWidth <= 0) {
      return null;
    }
    return CameraPosition(
      target: LatLng(location.mapLatitude, location.mapLongitude),
      zoom:
          (location.mapZoom +
                  math.log(cardWidth / locationCardSize.width) / math.ln2)
              .clamp(0, 22),
    );
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
            child: LocationCard(
              latitude: location.latitude,
              longitude: location.longitude,
              size: size,
              interactive: true,
              initialCameraPosition: cameraPosition(
                location,
                width: size.width,
              ),
            ),
          ),
        ],
      );
    },
  );
}
