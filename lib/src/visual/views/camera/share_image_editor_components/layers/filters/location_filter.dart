import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/api.dart';
import 'package:twonly/src/visual/components/location_card.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';

/// Shows the current location with an editable map viewport. The card stays
/// fixed; the receiver draws the map using the selected center and zoom.
class LocationFilter extends StatelessWidget {
  const LocationFilter({required this.layerData, super.key});

  final FilterLayerData layerData;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: layerData.showLocationCard,
    builder: (context, show, child) => Offstage(offstage: !show, child: child),
    child: Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 80,
          child: Center(
            child: FutureBuilder<FilterLocation?>(
              future: layerData.locationRequest,
              initialData: layerData.location,
              builder: (context, snapshot) => LocationCard(
                key: layerData.locationCardKey,
                latitude: snapshot.data?.latitude,
                longitude: snapshot.data?.longitude,
                interactive: true,
                initialCameraPosition: layerData.locationCamera,
                onCameraChanged: (position) =>
                    layerData.locationCamera = position,
                searching:
                    snapshot.data == null &&
                    snapshot.connectionState != ConnectionState.done,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
