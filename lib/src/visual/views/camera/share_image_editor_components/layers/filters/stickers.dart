import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/log.dart';

class Sticker {
  Sticker({required this.imageSrc, required this.source});
  factory Sticker.fromJson(Map<String, dynamic> json) {
    return Sticker(
      imageSrc: json['imageSrc'] as String,
      source: json['source'] as String? ?? '',
    );
  }
  final String imageSrc;
  final String source;
}

Future<List<Sticker>> getStickerIndex() async {
  final indexFile = File('${AppEnvironment.cacheDir}/stickers.json');
  var res = <Sticker>[];

  if (indexFile.existsSync() && kReleaseMode) {
    final lastModified = indexFile.lastModifiedSync();
    final difference = clock.now().difference(lastModified);
    final content = await indexFile.readAsString();
    final jsonList = json.decode(content) as List;
    res = jsonList
        .map((json) => Sticker.fromJson(json as Map<String, dynamic>))
        .toList();
    if (difference.inHours < 2) {
      return res;
    }
  }
  try {
    final response = await http.get(
      Uri.parse('https://twonly.eu/api/sticker/stickers.json'),
    );
    if (response.statusCode == 200) {
      await indexFile.writeAsString(response.body);
      final jsonList = json.decode(response.body) as List;
      return jsonList
          .map((json) => Sticker.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      return res;
    }
  } catch (e) {
    Log.error('$e');
    return res;
  }
}
