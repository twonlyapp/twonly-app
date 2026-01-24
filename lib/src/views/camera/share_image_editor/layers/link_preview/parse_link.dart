// Based on: https://github.com/sur950/any_link_preview
// Copyright (c) 2020-2024 Konakanchi Venkata Suresh Babu

import 'dart:convert';

import 'package:html/dom.dart' show Document;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/base.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/html.parser.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/json_ld.parser.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/mastodon.parser.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/og.parser.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/other.parser.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/twitter.parser.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/util.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/youtube.parser.dart';
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

    final data_ = _parse(document, url);

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

Metadata _parse(Document? document, String url) {
  final output = Metadata()..url = url;

  final allParsers = [
    // start with vendor specific to parse the vendor type
    MastodonParser(document),
    YoutubeParser(document, url),
    TwitterParser(document, url),

    JsonLdParser(document),
    OpenGraphParser(document),
    HtmlMetaParser(document),
    OtherParser(document),
  ];

  for (final parser in allParsers) {
    try {
      output.vendor ??= parser.vendor;
      output.title ??= parser.title;
      output.desc ??= parser.desc;
      if (output.vendor == Vendor.twitterPosting) {
        if (output.image == null) {
          if (parser.image?.contains('/media/') ?? false) {
            output.image ??= parser.image;
          }
        }
      } else {
        output.image ??= parser.image;
      }
      output.siteName ??= parser.siteName;
      output.publishDate ??= parser.publishDate;
      output.likeAction ??= parser.likeAction;
      output.shareAction ??= parser.shareAction;
      if (output.hasAllMetadata) break;
    } catch (e) {
      Log.error(e);
    }
  }

  return output;
}
