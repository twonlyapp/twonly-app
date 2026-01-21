import 'dart:convert';
import 'package:html/dom.dart';
import 'base.dart';
import 'util.dart';

class YoutubeParser with BaseMetaInfo {
  YoutubeParser(this.document, this.url) {
    _jsonData = _parseToJson(document);
  }

  @override
  String url;

  Document? document;
  dynamic _jsonData;

  dynamic _parseToJson(Document? document) {
    try {
      final data = document?.outerHtml
          .replaceAll('<html><head></head><body>', '')
          .replaceAll('</body></html>', '');
      if (data == null) return null;
      /* For multiline json file */
      // Replacing all new line characters with empty space
      // before performing json decode on data
      final d = jsonDecode(data.replaceAll('\n', ' '));
      return d;
    } catch (e) {
      return null;
    }
  }

  @override
  String? get title {
    final data = _jsonData;
    if (data is List<Map<String, dynamic>>) {
      return data.first['title'] as String?;
    } else if (data is Map) {
      return data.get('title');
    }
    return null;
  }

  @override
  String? get image {
    final data = _jsonData;
    if (data is List && data.isNotEmpty) {
      return _imgResultToStr(data.first['thumbnail_url']);
    } else if (data is Map) {
      return _imgResultToStr(data.getDynamic('thumbnail_url'));
    }
    return null;
  }

  @override
  String? get siteName {
    final data = _jsonData;
    if (data is List<Map<String, dynamic>>) {
      return data.first['provider_name'] as String?;
    } else if (data is Map) {
      return data.get('provider_name');
    }
    return null;
  }

  @override
  Vendor? get vendor => (Uri.parse(url).host.contains('youtube.com'))
      ? Vendor.youtubeVideo
      : null;

  String? _imgResultToStr(dynamic result) {
    if (result is List && result.isNotEmpty) result = result.first;
    if (result is String) return result;
    return null;
  }
}
