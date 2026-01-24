import 'dart:convert';

import 'package:html/dom.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/base.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/og.parser.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/util.dart';

/// Parses [Metadata] from `json-ld` data in `<script>` tags.
class JsonLdParser with BaseMetaInfo {
  JsonLdParser(this.document) {
    _parseToJson(document);
  }

  Document? document;
  Map<String, dynamic>? _jsonData;

  void _parseToJson(Document? document) {
    try {
      final data = document?.head
          ?.querySelector("script[type='application/ld+json']")
          ?.innerHtml;
      if (data == null) return;
      // For multiline json file
      // Replacing all new line characters with empty space
      // before performing json decode on data
      _jsonData =
          jsonDecode(data.replaceAll('\n', ' ')) as Map<String, dynamic>;
      // ignore: empty_catches
    } catch (e) {}
  }

  /// Get the [Metadata.title] from the <title> tag.
  @override
  String? get title {
    final data = _jsonData;
    if (data is Map<String, dynamic>) {
      return data['name'] as String? ?? data['headline'] as String?;
    }
    return null;
  }

  @override
  int? get shareAction {
    final statistics = _jsonData?['interactionStatistic'] as List<dynamic>?;
    if (statistics != null) {
      for (final statsDy in statistics) {
        final stats = statsDy as Map<String, dynamic>?;
        if (stats != null) {
          if (stats['interactionType'] == 'https://schema.org/ShareAction') {
            return stats['userInteractionCount'] as int?;
          }
        }
      }
    }
    return null;
  }

  @override
  int? get likeAction {
    final statistics = _jsonData?['interactionStatistic'] as List<dynamic>?;
    if (statistics != null) {
      for (final statsDy in statistics) {
        final stats = statsDy as Map<String, dynamic>?;
        if (stats != null) {
          if (stats['interactionType'] == 'https://schema.org/LikeAction') {
            return stats['userInteractionCount'] as int?;
          }
        }
      }
    }
    return null;
  }

  @override
  String? get desc {
    return _jsonData?['description'] as String?;
  }

  /// Get the [Metadata.image] from the first <img> tag in the body.
  @override
  String? get image {
    final data = _jsonData;
    return _imgResultToStr(
      data?.getDynamic('logo') ?? data?.getDynamic('image'),
    );
  }

  /// JSON LD does not have a siteName property, so we get it from
  /// [og:site_name] if available.
  @override
  String? get siteName => OpenGraphParser(document).siteName;

  String? _imgResultToStr(dynamic result) {
    if (result is List && result.isNotEmpty) {
      final tmp = result.first;
      if (tmp is String) return tmp;
    }
    if (result is String) return result;
    return null;
  }
}
