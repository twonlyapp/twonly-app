import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/components/image_editor/layers/filter_layer.dart';
import 'package:twonly/src/components/image_editor/layers/filters/datetime_filter.dart';
import 'package:twonly/src/proto/api/server_to_client.pb.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class LocationFilter extends StatefulWidget {
  const LocationFilter({super.key});

  @override
  State<LocationFilter> createState() => _LocationFilterState();
}

class _LocationFilterState extends State<LocationFilter> {
  String? _imageUrl;
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
      _searchForImage();
      setState(() {});
    }
  }

  void _searchForImage() async {
    if (location == null) return;
    List<String> imageIndex = await getStickerIndex();
    // Normalize the city and country for search
    String normalizedCity = location!.city.toLowerCase().replaceAll(' ', '_');
    String normalizedCountry = location!.county.toLowerCase();

    // Search for the city first
    for (var item in imageIndex) {
      if (item.contains('/cities/$normalizedCountry/')) {
        // Check if the item matches the normalized city
        if (item.endsWith('$normalizedCity.png')) {
          if (item.startsWith("/api/")) {
            _imageUrl = "https://twonly.eu/$item";
            setState(() {});
          }
          return;
        }
      }
    }

    // If city not found, search for the country
    if (_imageUrl == null) {
      for (var item in imageIndex) {
        if (item.contains('/countries/') && item.contains(normalizedCountry)) {
          if (item.startsWith("/api/")) {
            _imageUrl = "https://twonly.eu/$item";
            setState(() {});
          }
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageUrl != null) {
      return FilterSceleton(
        child: Positioned(
          bottom: 0,
          left: 40,
          right: 40,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: _imageUrl!,
            ),
          ),
        ),
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

Future<List<String>> getStickerIndex() async {
  final directory = await getApplicationCacheDirectory();
  final indexFile = File('${directory.path}/index.json');

  if (await indexFile.exists()) {
    final lastModified = await indexFile.lastModified();
    final difference = DateTime.now().difference(lastModified);
    if (difference.inHours < 24) {
      final content = await indexFile.readAsString();
      return await json.decode(content).whereType<String>().toList();
    }
  }
  final response =
      await http.get(Uri.parse('https://twonly.eu/api/sticker/index.json'));
  if (response.statusCode == 200) {
    await indexFile.writeAsString(response.body);
    return json.decode(response.body).whereType<String>().toList();
  } else {
    return [];
  }
}
