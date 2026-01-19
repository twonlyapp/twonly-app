import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parse_link.dart';

class LinkParserTest {
  LinkParserTest({
    required this.url,
    required this.title,
    required this.siteName,
    required this.desc,
    this.image,
  });

  final String url;
  final String title;
  final String siteName;
  final String desc;
  final String? image;
}

void main() {
  test('testing different urls', () async {
    final testCases = [
      LinkParserTest(
        url: 'https://mastodon.social/@islieb/115883317936171927',
        title: 'islieb? (@islieb@mastodon.social)',
        siteName: 'Mastodon',
        desc: 'Attached: 1 image',
        image:
            'https://files.mastodon.social/media_attachments/files/115/883/317/526/523/824/original/6fa7ef90ec68f1f1.jpg',
      ),
      LinkParserTest(
        url: 'https://chaos.social/@netzpolitik_feed/115921534467938262',
        title: 'netzpolitik.org (@netzpolitik_feed@chaos.social)',
        siteName: 'chaos.social',
        desc:
            'Die EU-Kommission erkennt Open Source als entscheidend für die digitale Souveränität an und wünscht sich mehr Kommerzialisierung. Bis April will Brüssel eine neue Strategie veröffentlichen. In einer laufenden Konsultation bekräftigen Stimmen aus ganz Europa, welche Vorteile sie in offenem Quellcode sehen.\n'
            '\n'
            'https://netzpolitik.org/2026/konsultation-eu-kommission-arbeitet-an-neuer-open-source-strategie/',
      ),
    ];

    for (final testCase in testCases) {
      final metadata = (await getMetadata(testCase.url))!;
      expect(metadata.title, testCase.title);
      expect(metadata.siteName, testCase.siteName);
      expect(metadata.desc, testCase.desc);
      expect(metadata.image, testCase.image);
    }
  });
}
