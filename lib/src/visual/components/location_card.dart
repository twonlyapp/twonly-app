import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/location_map.dart';

/// The location filter card's size, matching the live location card in a
/// chat.
const locationCardSize = Size(260, 190);

/// A map of one point at [locationCardSize], or the search state before it.
class LocationCard extends StatelessWidget {
  const LocationCard({
    this.latitude,
    this.longitude,
    this.searching = false,
    this.size = locationCardSize,
    this.interactive = false,
    this.initialCameraPosition,
    this.onCameraChanged,
    super.key,
  });

  final double? latitude;
  final double? longitude;
  final bool searching;
  final Size size;
  final bool interactive;
  final CameraPosition? initialCameraPosition;
  final ValueChanged<CameraPosition>? onCameraChanged;

  @override
  Widget build(BuildContext context) {
    final latitude = this.latitude;
    final longitude = this.longitude;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox.fromSize(
          size: size,
          child: latitude != null && longitude != null
              ? IgnorePointer(
                  ignoring: !interactive,
                  child: LocationMap(
                    latitude: latitude,
                    longitude: longitude,
                    interactive: interactive,
                    inline: true,
                    initialCameraPosition: initialCameraPosition,
                    onCameraChanged: onCameraChanged,
                  ),
                )
              : ColoredBox(
                  color: context.color.surface,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (searching)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(Icons.location_off_outlined),
                        const SizedBox(height: 12),
                        Text(
                          searching
                              ? context.lang.locationFilterSearching
                              : context.lang.locationFilterUnavailable,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
