import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/views/camera/image_editor/layers/filter_layer.dart';
import 'package:twonly/src/views/camera/image_editor/layers/filters/datetime_filter.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
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
    final res = await apiService.getCurrentLocation();
    if (res.isSuccess) {
      location = res.value.location;
      _searchForImage();
      if (mounted) setState(() {});
    }
  }

  void _searchForImage() async {
    if (location == null) return;
    List<Sticker> imageIndex = await getStickerIndex();
    // Normalize the city and country for search
    String normalizedCity = location!.city.toLowerCase().replaceAll(' ', '_');
    String normalizedCountry = location!.county.toLowerCase();

    // Search for the city first
    for (var item in imageIndex) {
      if (item.imageSrc.contains('/cities/$normalizedCountry/')) {
        // Check if the item matches the normalized city
        if (item.imageSrc.endsWith('$normalizedCity.png')) {
          if (item.imageSrc.startsWith("/api/")) {
            _imageUrl = "https://twonly.eu/${item.imageSrc}";
            if (mounted) setState(() {});
          }
          return;
        }
      }
    }

    // If city not found, search for the country
    if (_imageUrl == null) {
      for (var item in imageIndex) {
        if (item.imageSrc.contains('/countries/') &&
            item.imageSrc.contains(normalizedCountry)) {
          if (item.imageSrc.startsWith("/api/")) {
            _imageUrl = "https://twonly.eu/${item.imageSrc}";
            if (mounted) setState(() {});
          }
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageUrl != null) {
      return FilterSkeleton(
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
        return FilterSkeleton(
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

class Sticker {
  final String imageSrc;
  final String source;

  Sticker({required this.imageSrc, required this.source});

  factory Sticker.fromJson(Map<String, dynamic> json) {
    return Sticker(
      imageSrc: json['imageSrc'],
      source: json['source'] ?? '', // Handle null source
    );
  }
}

Future<List<Sticker>> getStickerIndex() async {
  final directory = await getApplicationCacheDirectory();
  final indexFile = File('${directory.path}/stickers.json');
  List<Sticker> res = [];

  if (await indexFile.exists() && !kDebugMode) {
    final lastModified = await indexFile.lastModified();
    final difference = DateTime.now().difference(lastModified);
    final content = await indexFile.readAsString();
    List<dynamic> jsonList = json.decode(content);
    res = jsonList.map((json) => Sticker.fromJson(json)).toList();
    if (difference.inHours < 2) {
      return res;
    }
  }
  try {
    final response = await http
        .get(Uri.parse('https://twonly.eu/api/sticker/stickers.json'));
    if (response.statusCode == 200) {
      await indexFile.writeAsString(response.body);
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Sticker.fromJson(json)).toList();
    } else {
      return res;
    }
  } catch (e) {
    Log.error("$e");
    return res;
  }
}
