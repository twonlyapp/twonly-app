import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/link_preview/parse_link.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/link_preview/parser/base.dart';

class LinkParserTest {
  LinkParserTest({
    required this.title,
    required this.url,
    this.desc,
    this.image,
    this.siteName,
    this.vendor,
    this.publishDate,
    this.likeAction,
    this.shareAction,
  });
  String title;
  String? desc;
  String? image;
  String url;
  String? siteName;

  Vendor? vendor;

  DateTime? publishDate;
  int? likeAction; // https://schema.org/LikeAction
  int? shareAction;
}

/// Serves the pages recorded on 2026-10-31 in `link_parser_fixtures`, so the
/// parsers are tested against fixed input rather than whatever the sites serve
/// today. Anything not recorded fails as a 404.
http.Client _recordedClient() {
  const directory = 'test/features/link_parser_fixtures';
  final entries =
      jsonDecode(File('$directory/responses.json').readAsStringSync())
          as List<dynamic>;
  final recorded = {
    for (final entry in entries.cast<Map<String, dynamic>>())
      entry['url'] as String: entry,
  };

  return MockClient((request) async {
    final entry = recorded[request.url.toString()];
    if (entry == null) return http.Response('not recorded', 404);

    return http.Response.bytes(
      File('$directory/${entry['body']}').readAsBytesSync(),
      entry['status'] as int,
      headers: (entry['headers'] as Map<String, dynamic>)
          .cast<String, String>(),
    );
  });
}

void main() {
  test('testing different urls', () async {
    final testCases = [
      LinkParserTest(
        url: 'https://mastodon.social/@islieb/115883317936171927',
        title: 'islieb? (@islieb@mastodon.social)',
        siteName: 'Mastodon.social',
        desc: 'Attached: 1 image',
        image:
            'https://files.mastodon.social/media_attachments/files/115/883/317/526/523/824/original/6fa7ef90ec68f1f1.jpg',
        vendor: Vendor.mastodonSocialMediaPosting,
        shareAction: 78,
        likeAction: 290,
      ),
      LinkParserTest(
        url: 'https://chaos.social/@netzpolitik_feed/115921534467938262',
        title: 'netzpolitik.org (@netzpolitik_feed@chaos.social)',
        siteName: 'chaos.social',
        desc:
            'Die EU-Kommission erkennt Open Source als entscheidend für die digitale Souveränität an und wünscht sich mehr Kommerzialisierung. Bis April will Brüssel eine neue Strategie veröffentlichen. In einer laufenden Konsultation bekräftigen Stimmen aus ganz Europa, welche Vorteile sie in offenem Quellcode sehen.\n'
            '\n'
            'https://netzpolitik.org/2026/konsultation-eu-kommission-arbeitet-an-neuer-open-source-strategie/',
        vendor: Vendor.mastodonSocialMediaPosting,
        shareAction: 73,
        likeAction: 100,
      ),
      LinkParserTest(
        title:
            'David Kriesel: Traue keinem Scan, den du nicht selbst gefälscht hast',
        url: 'https://www.youtube.com/watch?v=7FeqF1-Z1g0',
        siteName: 'YouTube',
        vendor: Vendor.youtubeVideo,
        image: 'https://i.ytimg.com/vi/7FeqF1-Z1g0/hqdefault.jpg',
      ),
      LinkParserTest(
        title: 'netzpolitik.org (@netzpolitik_org) on X',
        url: 'https://x.com/netzpolitik_org/status/1782791019412529665',
        siteName: 'X (formerly Twitter)',
        desc:
            'Jetzt ist wirklich Schluss: Wir verlassen als Redaktion das zur Plattform für Rechtsradikale verkommene Twitter – und freuen uns, wenn ihr uns woanders folgt.\n'
            '\n'
            'https://t.co/8W0hGly5bL',
        vendor: Vendor.twitterPosting,
      ),
      LinkParserTest(
        title: 'netzpolitik.org (@netzpolitik_org) on X',
        url: 'https://x.com/netzpolitik_org/status/1162346968124968960',
        siteName: 'X (formerly Twitter)',
        desc:
            'Weil unsere Datenanalyse zum Twitter-Account von Maaßen rechte Millieus und ihre Verbindungen offengelegt hat, haben wir einen rechten Shitstorm an der Backe. Klar ist: Wir lassen uns nicht einsch…',
        image:
            'https://pbs.twimg.com/media/ECF8Z5KWwAIBZ6o?format=webp&name=large',
        vendor: Vendor.twitterPosting,
      ),
    ];

    await http.runWithClient(() async {
      for (final testCase in testCases) {
        final metadata = (await getMetadata(testCase.url))!;
        expect(metadata.title, testCase.title);
        expect(metadata.siteName, testCase.siteName);
        expect(metadata.desc, testCase.desc);
        expect(metadata.url, testCase.url);
        expect(metadata.image, testCase.image);
        expect(metadata.vendor, testCase.vendor, reason: metadata.url);
        expect(metadata.shareAction, testCase.shareAction);
        expect(metadata.likeAction, testCase.likeAction);
        expect(metadata.publishDate, testCase.publishDate);
      }
    }, _recordedClient);
  });
}
