import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/api.dart';
import 'package:twonly/src/visual/components/location_card.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/filter.layer.dart';

/// Shows where the user is on a map. The card is left out of the captured
/// media; the sent coordinates let the receiver draw the map in its place.
class LocationFilter extends StatelessWidget {
  const LocationFilter({required this.layerData, super.key});

  final FilterLayerData layerData;

  @override
  Widget build(BuildContext context) => FilterSkeleton(
    child: Positioned(
      left: 0,
      right: 0,
      bottom: 80,
      child: Center(
        child: ValueListenableBuilder<bool>(
          valueListenable: layerData.showLocationCard,
          builder: (context, show, child) =>
              Offstage(offstage: !show, child: child),
          child: FutureBuilder<FilterLocation?>(
            future: layerData.locationRequest,
            initialData: layerData.location,
            builder: (context, snapshot) => LocationCard(
              key: layerData.locationCardKey,
              latitude: snapshot.data?.latitude,
              longitude: snapshot.data?.longitude,
              searching:
                  snapshot.data == null &&
                  snapshot.connectionState != ConnectionState.done,
            ),
          ),
        ),
      ),
    ),
  );
}
