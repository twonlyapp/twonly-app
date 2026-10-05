// ignore_for_file: constant_identifier_names

/*
 * Modified version of https://github.com/Fintasys/emoji_picker_flutter
 * MIT License
 * Copyright (c) 2024 Stefan Humm
 */

import 'package:flutter/material.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';

/// Container for a category and its emoji.
class CategoryEmoji {
  /// Constructor.
  const CategoryEmoji(this.category, this.emoji);

  /// Category instance.
  final Category category;

  /// Emoji in this category.
  final List<Emoji> emoji;

  /// Returns a copy with selected fields replaced.
  CategoryEmoji copyWith({Category? category, List<Emoji>? emoji}) {
    return CategoryEmoji(category ?? this.category, emoji ?? this.emoji);
  }
}

/// Optional action displayed after the category tabs.
enum CategoryExtraTab {
  /// Do not show an extra tab.
  NONE,

  /// Display a backspace button.
  BACKSPACE,

  /// Display a search button.
  SEARCH,
}

/// Icon and colors representing a category.
class CategoryIcon {
  /// Constructor.
  const CategoryIcon({
    required this.icon,
    this.color = const Color.fromRGBO(211, 211, 211, 1),
    this.selectedColor = const Color.fromRGBO(178, 178, 178, 1),
  });

  /// Category icon.
  final IconData icon;

  /// Default icon color.
  final Color color;

  /// Selected icon color.
  final Color selectedColor;
}

/// Icons shown for each emoji category.
class CategoryIcons {
  /// Constructor.
  const CategoryIcons({
    this.recentIcon = Icons.access_time,
    this.smileyIcon = Icons.tag_faces,
    this.animalIcon = Icons.pets,
    this.foodIcon = Icons.fastfood,
    this.activityIcon = Icons.directions_run,
    this.travelIcon = Icons.location_city,
    this.objectIcon = Icons.lightbulb_outline,
    this.symbolIcon = Icons.emoji_symbols,
    this.flagIcon = Icons.flag,
  });

  final IconData recentIcon;
  final IconData smileyIcon;
  final IconData animalIcon;
  final IconData foodIcon;
  final IconData activityIcon;
  final IconData travelIcon;
  final IconData objectIcon;
  final IconData symbolIcon;
  final IconData flagIcon;
}

/// Behavior of the recent category.
enum RecentTabBehavior {
  /// Do not show the recent category.
  NONE,

  /// Show the most recently used emoji first.
  RECENT,

  /// Show the most frequently used emoji first.
  POPULAR,
}
