import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/model/memory_flashbacks.model.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/database_values.dart';

MemoryItem _memory(DateTime date) => MemoryItem(
  mediaService: MediaFileService(
    MediaFile(
      mediaId: date.toIso8601String(),
      typeName: MediaType.image.name,
      cloudStateName: CloudState.none.name,
      requiresAuthentication: false,
      stored: true,
      isDraftMedia: false,
      isWidgetMedia: false,
      isFavorite: false,
      hasCropAnalyzed: false,
      hasThumbnail: true,
      galleryExportPending: false,
      createdAtSeconds: databaseSeconds(date),
    ),
  ),
  messages: [],
);

void main() {
  test('a new library shows the same day from previous months', () {
    final oneMonth = _memory(DateTime(2026, 9, 10));
    final twoMonths = _memory(DateTime(2026, 8, 10));
    final elevenMonths = _memory(DateTime(2025, 11, 10));
    final result = MemoryFlashbacks.fromItems([
      twoMonths,
      _memory(DateTime(2026, 9, 9)),
      _memory(DateTime(2026, 10, 10)),
      _memory(DateTime(2026, 11, 10)),
      elevenMonths,
      oneMonth,
    ], now: DateTime(2026, 10, 10));

    expect(result.period, MemoryFlashbackPeriod.months);
    expect(result.items.keys, [1, 2, 11]);
    expect(result.items[1], [oneMonth]);
    expect(result.items[2], [twoMonths]);
    expect(result.items[11], [elevenMonths]);
  });

  test('the first anniversary switches to yearly flashbacks for the day', () {
    final anniversary = _memory(DateTime(2025, 10, 10, 23));
    final result = MemoryFlashbacks.fromItems([
      _memory(DateTime(2026, 9, 10)),
      anniversary,
    ], now: DateTime(2026, 10, 10, 8));

    expect(result.period, MemoryFlashbackPeriod.years);
    expect(result.items, {
      1: [anniversary],
    });
  });

  test('a memory just short of a year keeps the monthly view', () {
    final recent = _memory(DateTime(2026, 9, 10));
    final result = MemoryFlashbacks.fromItems([
      _memory(DateTime(2025, 10, 11)),
      recent,
    ], now: DateTime(2026, 10, 10));

    expect(result.period, MemoryFlashbackPeriod.months);
    expect(result.items, {
      1: [recent],
    });
  });

  test('an older library stays yearly without an anniversary today', () {
    final result = MemoryFlashbacks.fromItems([
      _memory(DateTime(2025, 10, 9)),
      _memory(DateTime(2026, 9, 10)),
    ], now: DateTime(2026, 10, 10));

    expect(result.period, MemoryFlashbackPeriod.years);
    expect(result.items, isEmpty);
  });

  test('yearly flashbacks include each matching year in ascending order', () {
    final oneYear = _memory(DateTime(2025, 10, 10));
    final twoYears = _memory(DateTime(2024, 10, 10));
    final result = MemoryFlashbacks.fromItems([
      twoYears,
      _memory(DateTime(2024, 10, 9)),
      oneYear,
    ], now: DateTime(2026, 10, 10));

    expect(result.period, MemoryFlashbackPeriod.years);
    expect(result.items.keys, [1, 2]);
    expect(result.items[1], [oneYear]);
    expect(result.items[2], [twoYears]);
  });

  test('monthly anniversaries use the last day of shorter months', () {
    for (final year in [2024, 2026]) {
      final lastFebruaryDay = year == 2024 ? 29 : 28;
      final february = _memory(DateTime(year, 2, lastFebruaryDay));
      final january = _memory(DateTime(year, 1, 31));
      final result = MemoryFlashbacks.fromItems([
        january,
        _memory(DateTime(year, 2, lastFebruaryDay - 1)),
        february,
      ], now: DateTime(year, 3, 31));

      expect(result.period, MemoryFlashbackPeriod.months);
      expect(result.items, {
        1: [february],
        2: [january],
      });
    }
  });

  test('February 29 does not switch early because of date overflow', () {
    final recent = _memory(DateTime(2024, 1, 29));
    final result = MemoryFlashbacks.fromItems([
      _memory(DateTime(2023, 3)),
      recent,
    ], now: DateTime(2024, 2, 29));

    expect(result.period, MemoryFlashbackPeriod.months);
    expect(result.items, {
      1: [recent],
    });
  });

  test('photos within a flashback open newest first', () {
    final morning = _memory(DateTime(2026, 9, 10, 8));
    final evening = _memory(DateTime(2026, 9, 10, 20));
    final result = MemoryFlashbacks.fromItems([
      morning,
      evening,
    ], now: DateTime(2026, 10, 10));

    expect(result.items[1], [evening, morning]);
  });

  test('an empty library has no flashbacks', () {
    final result = MemoryFlashbacks.fromItems([], now: DateTime(2026, 10, 10));
    expect(result.items, isEmpty);
  });
}
