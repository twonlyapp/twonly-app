import 'dart:collection';

import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/utils/database_values.dart';

enum MemoryFlashbackPeriod { months, years }

class MemoryFlashbacks {
  const MemoryFlashbacks({
    required this.period,
    required this.items,
  });

  factory MemoryFlashbacks.fromItems(
    List<MemoryItem> galleryItems, {
    required DateTime now,
  }) {
    final yearAgo = _monthsAgo(now, 12);
    final period =
        galleryItems.any((item) {
          final createdAt = item.mediaService.mediaFile.createdAt;
          final date = DateTime(createdAt.year, createdAt.month, createdAt.day);
          return !date.isAfter(yearAgo);
        })
        ? MemoryFlashbackPeriod.years
        : MemoryFlashbackPeriod.months;
    final groups = SplayTreeMap<int, List<MemoryItem>>();

    for (final item in galleryItems) {
      final date = item.mediaService.mediaFile.createdAt;
      final int elapsed;
      if (period == MemoryFlashbackPeriod.months) {
        elapsed = (now.year - date.year) * 12 + now.month - date.month;
        if (elapsed < 1 || elapsed >= 12) continue;
        // On the 29th–31st, use the last day of shorter months.
        if (date.day != _monthsAgo(now, elapsed).day) continue;
      } else {
        elapsed = now.year - date.year;
        if (elapsed < 1 || date.month != now.month || date.day != now.day) {
          continue;
        }
      }
      groups.putIfAbsent(elapsed, () => []).add(item);
    }

    for (final items in groups.values) {
      items.sort(
        (a, b) => b.mediaService.mediaFile.createdAt.compareTo(
          a.mediaService.mediaFile.createdAt,
        ),
      );
    }

    return MemoryFlashbacks(period: period, items: groups);
  }

  final MemoryFlashbackPeriod period;
  final Map<int, List<MemoryItem>> items;

  static DateTime _monthsAgo(DateTime now, int months) {
    final month = DateTime(now.year, now.month - months);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return DateTime(month.year, month.month, now.day.clamp(1, lastDay));
  }
}
