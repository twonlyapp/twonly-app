import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parse_link.dart';
import 'package:twonly/src/views/camera/share_image_editor/layers/link_preview/parser/base.dart';

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
        vendor: Vendor.mastodonSocialMediaPosting,
        shareAction: 90,
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
        shareAction: 70,
        likeAction: 90,
      ),
      LinkParserTest(
        title: 'Kuketz-Blog 🛡 (@kuketzblog@social.tchncs.de)',
        url: 'https://social.tchncs.de/@kuketzblog/115898752560771936',
        siteName: 'Mastodon',
        desc:
            'AWS verspricht jetzt »Souveränität« mit einem »europäischen« Cloud-Angebot – Standort Deutschland, großes Vertrauens-Theater.\n'
            '\n'
            'Nur: Souveränität ist keine Postleitzahl. Wenn der Anbieter Amazon heißt, bleibt es dasselbe Märchen mit neuem Umschlag: Der Cloud Act, FISA etc. gilt trotzdem. US-Recht schlägt Geografie. Das Gerede von »Souveränität« ist kein Konzept, sondern Marketing.\n'
            '\n'
            'https://www.heise.de/news/AWS-verspricht-Souveraenitaet-mit-europaeischem-Cloudangebot-11141800.html',
        vendor: Vendor.mastodonSocialMediaPosting,
        shareAction: 15,
        likeAction: 190,
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
            'Weil unsere Datenanalyse zum Twitter-Account von Maaßen rechte Millieus und ihre Verbindungen offengelegt hat, haben wir einen rechten Shitstorm an der Backe. Klar ist: Wir lassen uns nicht einschüchtern und freuen uns auf Unterstützung! \n'
            '\n'
            'https://t.co/MQZ7ulHakF',
        image: 'https://pbs.twimg.com/media/ECF8Z5KWwAIBZ6o.jpg:large',
        vendor: Vendor.twitterPosting,
      ),
      LinkParserTest(
        title: 'twonly Public Launch',
        desc:
            'After about a year of development, twonly is finally ready for its public launch.',
        url: 'https://twonly.eu/en/blog/2026-public-launch.html',
        image: 'https://twonly.eu/assets/blog/2026-public-launch.webp',
      ),
    ];

    for (final testCase in testCases) {
      final metadata = (await getMetadata(testCase.url))!;
      expect(metadata.title, testCase.title);
      expect(metadata.siteName, testCase.siteName);
      expect(metadata.desc, testCase.desc);
      expect(metadata.url, testCase.url);
      expect(metadata.image, testCase.image);
      expect(metadata.vendor, testCase.vendor, reason: metadata.url);
      if (testCase.shareAction != null) {
        expect(
          metadata.shareAction,
          greaterThanOrEqualTo(testCase.shareAction!),
        );
      }
      if (testCase.shareAction != null) {
        expect(
          metadata.likeAction,
          greaterThanOrEqualTo(testCase.likeAction!),
        );
      }
      expect(metadata.publishDate, testCase.publishDate);
    }
  });
}
