// Based on: https://github.com/sur950/any_link_preview
// Copyright (c) 2020-2024 Konakanchi Venkata Suresh Babu

import 'dart:convert';

import 'package:html/dom.dart' show Document;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/base.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/html_parser.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/json_ld_parser.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/og_parser.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/other_parser.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/twitter_parser.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/util.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/youtube_parser.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/utils.dart';

Future<Metadata?> getMetadata(String link) async {
  const userAgent = 'WhatsApp/2.21.12.21 A';
  try {
    final linkToFetch = link.trim();
    final info = await getInfo(linkToFetch, userAgent);

    final img = info?.image ?? '';
    if (img.isNotEmpty) {
      info?.image = resolveImageUrl(link, img);
    }

    return info;
  } catch (error) {
    return null;
  }
}

String resolveImageUrl(String baseUrl, String imageUrl) {
  try {
    final baseUri = Uri.parse(baseUrl);
    return baseUri.resolve(imageUrl).toString();
  } catch (e) {
    return imageUrl;
  }
}

Future<Metadata?> getInfo(
  String url,
  String userAgent,
) async {
  Metadata? info;

  info = Metadata()
    ..title = getDomain(url)
    ..desc = url
    ..siteName = getDomain(url)
    ..url = url;

  try {
    final videoId = getYouTubeVideoId(url);
    final response = videoId == null
        ? await fetchWithRedirects(
            Uri.parse(url),
            userAgent: userAgent,
          )
        : await getYoutubeData(
            videoId,
            userAgent,
          );

    final headerContentType = response.headers['content-type'];

    if (headerContentType != null && headerContentType.startsWith('image/')) {
      info
        ..title = ''
        ..desc = ''
        ..siteName = ''
        ..image = url;
      return info;
    }

    final document = responseToDocument(response);
    if (document == null) return info;

    final data_ = _parse(document, url: url);

    return data_;
  } catch (error) {
    Log.warn('Error in $url response ($error)');
    return info;
  }
}

Document? responseToDocument(http.Response response) {
  if (response.statusCode != 200) return null;

  Document? document;
  try {
    document = parse(utf8.decode(response.bodyBytes));
  } catch (err) {
    return document;
  }

  return document;
}

Metadata _parse(Document? document, {String? url}) {
  final output = Metadata();

  final parsers = [
    _openGraph(document),
    _twitterCard(document),
    _youtubeCard(document),
    _jsonLdSchema(document),
    _htmlMeta(document),
    _otherParser(document),
  ];

  for (final p in parsers) {
    if (p == null) continue;

    output.title ??= p.title;
    output.desc ??= p.desc;
    output.image ??= p.image;
    output.siteName ??= p.siteName;
    output.url ??= p.url ?? url;

    if (output.hasAllMetadata) break;
  }

  final url_ = output.url ?? url;
  final image = output.image;
  if (url_ != null && image != null) {
    output.image = Uri.parse(url_).resolve(image).toString();
  }

  return output;
}

Metadata? _openGraph(Document? document) {
  try {
    return OpenGraphParser(document).parse();
  } catch (e) {
    return null;
  }
}

Metadata? _htmlMeta(Document? document) {
  try {
    return HtmlMetaParser(document).parse();
  } catch (e) {
    return null;
  }
}

Metadata? _jsonLdSchema(Document? document) {
  try {
    return JsonLdParser(document).parse();
  } catch (e) {
    return null;
  }
}

Metadata? _youtubeCard(Document? document) {
  try {
    return YoutubeParser(document).parse();
  } catch (e) {
    return null;
  }
}

Metadata? _twitterCard(Document? document) {
  try {
    return TwitterParser(document).parse();
  } catch (e) {
    return null;
  }
}

Metadata? _otherParser(Document? document) {
  try {
    return OtherParser(document).parse();
  } catch (e) {
    return null;
  }
}
