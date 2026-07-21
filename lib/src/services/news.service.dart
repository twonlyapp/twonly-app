import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/log.dart';

class BlogEntry {
  BlogEntry({
    required this.title,
    required this.link,
    required this.guid,
    required this.description,
    required this.imageUrl,
    this.pubDate,
  });

  factory BlogEntry.fromJson(Map<String, dynamic> json) => BlogEntry(
    title: (json['title'] as String?) ?? '',
    link: (json['link'] as String?) ?? '',
    guid: (json['guid'] as String?) ?? '',
    description: (json['description'] as String?) ?? '',
    imageUrl: (json['imageUrl'] as String?) ?? '',
    pubDate: json['pubDate'] != null
        ? DateTime.tryParse(json['pubDate'] as String)
        : null,
  );

  final String title;
  final String link;
  final String guid;
  final String description;
  final String imageUrl;
  final DateTime? pubDate;

  Map<String, dynamic> toJson() => {
    'title': title,
    'link': link,
    'guid': guid,
    'description': description,
    'imageUrl': imageUrl,
    'pubDate': pubDate?.toIso8601String(),
  };

  @override
  String toString() {
    return 'BlogEntry(title: $title, link: $link, guid: $guid, description: $description, imageUrl: $imageUrl, pubDate: $pubDate)';
  }
}

class NewsService {
  List<BlogEntry> entries = [];
  Set<String> openedGuids = {};
  DateTime? lastDownloadedAt;
  bool hasLoadedBefore = false;

  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  File get _cacheFile =>
      File(join(AppEnvironment.supportDir, 'news_feed.json'));

  Future<void> init() async {
    try {
      await loadCache();
    } catch (e) {
      Log.error('Failed to load news cache: $e');
    }
  }

  Future<void> loadCache() async {
    final file = _cacheFile;
    if (!file.existsSync()) {
      return;
    }
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;

    hasLoadedBefore = json['hasLoadedBefore'] as bool? ?? false;

    final lastDownloadedStr = json['lastDownloadedAt'] as String?;
    if (lastDownloadedStr != null) {
      lastDownloadedAt = DateTime.tryParse(lastDownloadedStr);
    }

    final openedList = json['openedGuids'] as List<dynamic>? ?? [];
    openedGuids = openedList.map((e) => e.toString()).toSet();

    final entriesList = json['entries'] as List<dynamic>? ?? [];
    entries = entriesList
        .map((e) => BlogEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    _updateUnreadCount();
  }

  Future<void> saveCache() async {
    final file = _cacheFile;
    final json = {
      'hasLoadedBefore': hasLoadedBefore,
      'lastDownloadedAt': lastDownloadedAt?.toIso8601String(),
      'openedGuids': openedGuids.toList(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
    await file.writeAsString(jsonEncode(json));
  }

  void _updateUnreadCount() {
    var count = 0;
    for (final entry in entries) {
      if (!openedGuids.contains(entry.guid)) {
        count++;
      }
    }
    unreadCountNotifier.value = count;
  }

  Future<void> markAllAsRead() async {
    for (final entry in entries) {
      openedGuids.add(entry.guid);
    }
    _updateUnreadCount();
    await saveCache();
  }

  Future<void> fetchFeed({http.Client? client, bool force = false}) async {
    try {
      final lang = ui.PlatformDispatcher.instance.locale.languageCode;
      final url = lang == 'de'
          ? 'https://twonly.eu/de/blog/rss.xml'
          : 'https://twonly.eu/en/blog/rss.xml';

      final response = client != null
          ? await client.get(Uri.parse(url))
          : await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        Log.error('Failed to download RSS feed: code ${response.statusCode}');
        return;
      }

      final xml = utf8.decode(response.bodyBytes);
      final newEntries = _parseRss(xml);

      if (!hasLoadedBefore) {
        // First run: mark all fetched as already opened
        for (final entry in newEntries) {
          openedGuids.add(entry.guid);
        }
        hasLoadedBefore = true;
      }

      entries = newEntries;
      lastDownloadedAt = DateTime.now();

      _updateUnreadCount();
      await saveCache();
      Log.info(
        'Successfully fetched ${entries.length} news entries. Unread count: ${unreadCountNotifier.value}',
      );
    } catch (e) {
      Log.error('Failed to fetch news feed: $e');
    }
  }

  List<BlogEntry> _parseRss(String xml) {
    final entries = <BlogEntry>[];
    final itemRegex = RegExp(r'<item>([\s\S]*?)<\/item>');
    final matches = itemRegex.allMatches(xml);

    for (final match in matches) {
      final itemContent = match.group(1) ?? '';

      final titleMatch = RegExp(
        r'<title>([\s\S]*?)<\/title>',
      ).firstMatch(itemContent);
      final title = _stripCdata(titleMatch?.group(1) ?? '');

      final linkMatch = RegExp(
        r'<link>([\s\S]*?)<\/link>',
      ).firstMatch(itemContent);
      final link = _stripCdata(linkMatch?.group(1) ?? '');

      final guidMatch = RegExp(
        r'<guid[^>]*?>([\s\S]*?)<\/guid>',
      ).firstMatch(itemContent);
      final guid = _stripCdata(guidMatch?.group(1) ?? link);

      final descMatch = RegExp(
        r'<description>([\s\S]*?)<\/description>',
      ).firstMatch(itemContent);
      final descriptionRaw = _stripCdata(descMatch?.group(1) ?? '');
      final description = descriptionRaw
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll('&apos;', "'")
          .replaceAll('&#39;', "'")
          .replaceAll(RegExp('<[^>]*>'), '')
          .trim();

      var imageUrl = '';
      final enclosureMatch = RegExp(
        r'<enclosure\s+[^>]*?url="([^"]+)"',
      ).firstMatch(itemContent);
      if (enclosureMatch != null) {
        imageUrl = enclosureMatch.group(1) ?? '';
      }
      if (imageUrl.isEmpty) {
        final mediaMatch = RegExp(
          r'<media:content\s+[^>]*?url="([^"]+)"',
        ).firstMatch(itemContent);
        if (mediaMatch != null) {
          imageUrl = mediaMatch.group(1) ?? '';
        }
      }

      final pubDateMatch = RegExp(
        r'<pubDate>([\s\S]*?)<\/pubDate>',
      ).firstMatch(itemContent);
      DateTime? pubDate;
      if (pubDateMatch != null) {
        final pubDateStr = pubDateMatch.group(1) ?? '';
        pubDate = DateTime.tryParse(pubDateStr);
        pubDate ??= _parseRfc2822(pubDateStr);
      }

      entries.add(
        BlogEntry(
          title: title,
          link: link,
          guid: guid,
          description: description,
          imageUrl: imageUrl,
          pubDate: pubDate,
        ),
      );
    }

    return entries;
  }

  String _stripCdata(String input) {
    var s = input.trim();
    if (s.startsWith('<![CDATA[')) {
      s = s.substring(9);
    }
    if (s.endsWith(']]>')) {
      s = s.substring(0, s.length - 3);
    }
    return s.trim();
  }

  DateTime? _parseRfc2822(String dateString) {
    try {
      var cleaned = dateString.trim();
      if (cleaned.contains(',')) {
        cleaned = cleaned.split(',')[1].trim();
      }
      final parts = cleaned.split(RegExp(r'\s+'));
      if (parts.length < 4) return null;

      final day = int.tryParse(parts[0]) ?? 1;
      final monthStr = parts[1].toLowerCase();
      final year = int.tryParse(parts[2]) ?? DateTime.now().year;

      final timeParts = parts[3].split(':');
      final hour = timeParts.isNotEmpty ? (int.tryParse(timeParts[0]) ?? 0) : 0;
      final minute = timeParts.length > 1
          ? (int.tryParse(timeParts[1]) ?? 0)
          : 0;
      final second = timeParts.length > 2
          ? (int.tryParse(timeParts[2]) ?? 0)
          : 0;

      const months = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };
      final monthStringPart = monthStr.length > 3
          ? monthStr.substring(0, 3)
          : monthStr;
      final month = months[monthStringPart] ?? 1;

      return DateTime.utc(year, month, day, hour, minute, second);
    } catch (e) {
      Log.warn('Failed to parse date: $e');
      return null;
    }
  }
}
