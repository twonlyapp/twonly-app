import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/news.service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late NewsService newsServiceInstance;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('news_service_test');
    AppEnvironment.initTesting(
      customCacheDir: join(tempDir.path, 'cache'),
      customSupportDir: join(tempDir.path, 'support'),
    );
    Directory(AppEnvironment.supportDir).createSync(recursive: true);
    Directory(AppEnvironment.cacheDir).createSync(recursive: true);

    await locator.reset();
    locator.registerSingleton<NewsService>(NewsService());
    newsServiceInstance = newsService;
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  const rssXml = '''
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/">
<channel>
    <title>twonly Blog</title>
    <link>https://twonly.eu/en/blog/</link>
    <description>Latest news, privacy insights, and development updates from twonly.</description>
    <language>en</language>
    <lastBuildDate>Mon, 20 Jul 2026 12:23:32 GMT</lastBuildDate>
    <atom:link href="https://twonly.eu/en/blog/rss.xml" rel="self" type="application/rss+xml" />
        <item>
            <title><![CDATA[Finding Friends Without Phone Numbers]]></title>
            <link>https://twonly.eu/en/blog/2026-mutual-friends.html</link>
            <guid isPermaLink="true">https://twonly.eu/en/blog/2026-mutual-friends.html</guid>
            <pubDate>Sun, 03 May 2026 00:00:00 GMT</pubDate>
            <author><![CDATA[Tobias Müller]]></author>
            <description><![CDATA[Finding your friends on a messenger app usually means giving up your phone number. We’ve built a way to find and verify your contacts through the people you already know, all while keeping your personal identifiers private. No phone numbers, no tracking.]]></description>
            <enclosure url="https://twonly.eu/assets/blog/2026-mutual-friends/2026-mutual-friends.webp" length="258020" type="image/webp" />
            <media:content url="https://twonly.eu/assets/blog/2026-mutual-friends/2026-mutual-friends.webp" medium="image" type="image/webp" />
        </item>
</channel>
</rss>''';

  const rssXmlWithTwoItems = '''
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/">
<channel>
    <title>twonly Blog</title>
    <link>https://twonly.eu/en/blog/</link>
    <description>Latest news, privacy insights, and development updates from twonly.</description>
    <language>en</language>
    <lastBuildDate>Mon, 20 Jul 2026 12:23:32 GMT</lastBuildDate>
    <atom:link href="https://twonly.eu/en/blog/rss.xml" rel="self" type="application/rss+xml" />
        <item>
            <title><![CDATA[Finding Friends Without Phone Numbers]]></title>
            <link>https://twonly.eu/en/blog/2026-mutual-friends.html</link>
            <guid isPermaLink="true">https://twonly.eu/en/blog/2026-mutual-friends.html</guid>
            <pubDate>Sun, 03 May 2026 00:00:00 GMT</pubDate>
            <author><![CDATA[Tobias Müller]]></author>
            <description><![CDATA[Finding your friends on a messenger app usually means giving up your phone number. We’ve built a way to find and verify your contacts through the people you already know, all while keeping your personal identifiers private. No phone numbers, no tracking.]]></description>
            <enclosure url="https://twonly.eu/assets/blog/2026-mutual-friends/2026-mutual-friends.webp" length="258020" type="image/webp" />
            <media:content url="https://twonly.eu/assets/blog/2026-mutual-friends/2026-mutual-friends.webp" medium="image" type="image/webp" />
        </item>
        <item>
            <title><![CDATA[New Update Available]]></title>
            <link>https://twonly.eu/en/blog/new-update.html</link>
            <guid isPermaLink="true">https://twonly.eu/en/blog/new-update.html</guid>
            <pubDate>Mon, 20 Jul 2026 12:00:00 GMT</pubDate>
            <author><![CDATA[Tobias Müller]]></author>
            <description><![CDATA[A brand <a href="https://twonly.eu">new version</a> of twonly has been released.]]></description>
            <enclosure url="https://twonly.eu/assets/blog/new-update/new-update.webp" length="12345" type="image/webp" />
        </item>
</channel>
</rss>''';

  test('Initial fetch feed marks all articles as read', () async {
    final mockClient = MockClient((request) async {
      return http.Response.bytes(utf8.encode(rssXml), 200);
    });

    await newsServiceInstance.init();
    expect(newsServiceInstance.hasLoadedBefore, isFalse);
    expect(newsServiceInstance.unreadCountNotifier.value, 0);

    await newsServiceInstance.fetchFeed(client: mockClient);

    expect(newsServiceInstance.hasLoadedBefore, isTrue);
    expect(newsServiceInstance.entries.length, 1);
    expect(newsServiceInstance.unreadCountNotifier.value, 0);
    expect(
      newsServiceInstance.openedGuids.contains(
        'https://twonly.eu/en/blog/2026-mutual-friends.html',
      ),
      isTrue,
    );
  });

  test('Subsequent fetch feed detects new articles as unread', () async {
    final mockClient1 = MockClient((request) async {
      return http.Response.bytes(utf8.encode(rssXml), 200);
    });

    await newsServiceInstance.init();
    await newsServiceInstance.fetchFeed(client: mockClient1);

    expect(newsServiceInstance.unreadCountNotifier.value, 0);

    final mockClient2 = MockClient((request) async {
      return http.Response.bytes(utf8.encode(rssXmlWithTwoItems), 200);
    });

    await newsServiceInstance.fetchFeed(client: mockClient2);

    expect(newsServiceInstance.entries.length, 2);
    expect(newsServiceInstance.unreadCountNotifier.value, 1);
    expect(
      newsServiceInstance.entries[1].description,
      'A brand new version of twonly has been released.',
    );
  });

  test('markAllAsRead clears unread count', () async {
    final mockClient1 = MockClient((request) async {
      return http.Response.bytes(utf8.encode(rssXml), 200);
    });

    await newsServiceInstance.init();
    await newsServiceInstance.fetchFeed(client: mockClient1);

    final mockClient2 = MockClient((request) async {
      return http.Response.bytes(utf8.encode(rssXmlWithTwoItems), 200);
    });

    await newsServiceInstance.fetchFeed(client: mockClient2);
    expect(newsServiceInstance.unreadCountNotifier.value, 1);

    await newsServiceInstance.markAllAsRead();
    expect(newsServiceInstance.unreadCountNotifier.value, 0);
  });

  test('Cache loads correctly and restores state', () async {
    final mockClient = MockClient((request) async {
      return http.Response.bytes(utf8.encode(rssXml), 200);
    });

    await newsServiceInstance.init();
    await newsServiceInstance.fetchFeed(client: mockClient);

    final newServiceInstance = NewsService();
    await newServiceInstance.init();

    expect(newServiceInstance.hasLoadedBefore, isTrue);
    expect(newServiceInstance.entries.length, 1);
    expect(newServiceInstance.unreadCountNotifier.value, 0);
    expect(
      newServiceInstance.openedGuids.contains(
        'https://twonly.eu/en/blog/2026-mutual-friends.html',
      ),
      isTrue,
    );
  });
}
