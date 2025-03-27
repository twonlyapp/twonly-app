import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/components/image_editor/layers/filter_layer.dart';
import 'package:twonly/src/components/image_editor/layers/filters/datetime_filter.dart';
import 'package:twonly/src/components/image_editor/layers/filters/image_filter.dart';
import 'package:twonly/src/proto/api/server_to_client.pb.dart';

class LocationFilter extends StatefulWidget {
  const LocationFilter({super.key});

  @override
  State<LocationFilter> createState() => _LocationFilterState();
}

Map<String, String> cities = {
  "Frankfurt am Main": "germany_frankfurt_am_main.png",
};

Map<String, String> countries = {
  "Germany": "germany.png",
};

class _LocationFilterState extends State<LocationFilter> {
  String? selectedImage;
  String overlayText = "";
  Response_Location? location;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future initAsync() async {
    final res = await apiProvider.getCurrentLocation();
    if (res.isSuccess) {
      location = res.value.location;

      if (cities.containsKey(location!.city)) {
        selectedImage = cities[location!.city];
        overlayText = location!.city;
      } else if (countries.containsKey(location!.county)) {
        selectedImage = countries[location!.county];
        overlayText = location!.county;
      }

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedImage != null) {
      return Stack(
        children: [
          ImageFilter(imagePath: "location/${selectedImage!}"),
          Positioned(
            bottom: 55,
            left: 0,
            right: 0,
            child: Center(
              child: Text(overlayText),
            ),
          )
        ],
      );
    }

    if (location != null) {
      if (location!.county != "-") {
        return FilterSceleton(
          child: Positioned(
            bottom: 50,
            left: 40,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                FilterText(location!.city),
                FilterText(location!.region),
                FilterText(location!.county),
              ],
            ),
          ),
        );
      }
    }

    return DateTimeFilter(color: Colors.black);
  }
}
