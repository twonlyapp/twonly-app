/*
 * Modified version of https://github.com/Fintasys/emoji_picker_flutter
 * MIT License
 * Copyright (c) 2024 Stefan Humm
 */

import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';
import 'package:flutter/material.dart';

/// Template class for custom implementation
/// Inhert this class to create your own Category view
abstract class CategoryView extends StatefulWidget {
  /// Constructor
  const CategoryView(
    this.config,
    this.state,
    this.tabController,
    this.pageController, {
    super.key,
  });

  /// Config for customizations
  final Config config;

  /// State that holds current emoji data
  final EmojiViewState state;

  /// TabController for Category view
  final TabController tabController;

  /// Page Controller of Emoji view
  final PageController pageController;
}

/// Returns the icon for the category
IconData getIconForCategory(CategoryIcons categoryIcons, Category category) {
  switch (category) {
    case Category.RECENT:
      return categoryIcons.recentIcon;
    case Category.SMILEYS:
      return categoryIcons.smileyIcon;
    case Category.ANIMALS:
      return categoryIcons.animalIcon;
    case Category.FOODS:
      return categoryIcons.foodIcon;
    case Category.TRAVEL:
      return categoryIcons.travelIcon;
    case Category.ACTIVITIES:
      return categoryIcons.activityIcon;
    case Category.OBJECTS:
      return categoryIcons.objectIcon;
    case Category.SYMBOLS:
      return categoryIcons.symbolIcon;
    case Category.FLAGS:
      return categoryIcons.flagIcon;
  }
}

/// Template class for custom implementation
/// Inhert this class to create your own category view state
class CategoryViewState<T extends CategoryView> extends State<T>
    with SkinToneOverlayStateMixin {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('Category View implementation missing');
  }
}

/// Default category view.
class DefaultCategoryView extends CategoryView {
  /// Constructor.
  const DefaultCategoryView(
    super.config,
    super.state,
    super.tabController,
    super.pageController, {
    this.onCategorySelected,
    super.key,
  });

  /// Callback used to jump inside the continuous emoji list.
  final ValueChanged<int>? onCategorySelected;

  @override
  DefaultCategoryViewState createState() => DefaultCategoryViewState();
}

/// State for the default category view.
class DefaultCategoryViewState extends CategoryViewState<DefaultCategoryView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.config.categoryViewConfig.backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: DefaultCategoryTabBar(
              widget.config,
              widget.tabController,
              widget.pageController,
              widget.state.categoryEmoji,
              closeSkinToneOverlay,
              onCategorySelected: widget.onCategorySelected,
            ),
          ),
          _buildExtraTab(widget.config.categoryViewConfig.extraTab),
        ],
      ),
    );
  }

  Widget _buildExtraTab(CategoryExtraTab? extraTab) {
    if (extraTab == CategoryExtraTab.BACKSPACE) {
      return BackspaceButton(
        widget.config,
        widget.state.onBackspacePressed,
        widget.state.onBackspaceLongPressed,
        widget.config.categoryViewConfig.backspaceColor,
      );
    }
    if (extraTab == CategoryExtraTab.SEARCH) {
      return SearchButton(
        widget.config,
        widget.state.onShowSearchView,
        widget.config.categoryViewConfig.iconColor,
      );
    }
    return const SizedBox.shrink();
  }
}

/// Category navigation for the continuous emoji list.
class DefaultCategoryTabBar extends StatelessWidget {
  /// Constructor.
  const DefaultCategoryTabBar(
    this.config,
    this.tabController,
    this.pageController,
    this.categoryEmojis,
    this.closeSkinToneOverlay, {
    this.onCategorySelected,
    super.key,
  });

  final Config config;
  final TabController tabController;
  final PageController pageController;
  final List<CategoryEmoji> categoryEmojis;
  final VoidCallback closeSkinToneOverlay;

  /// Callback used by continuous emoji lists to navigate to a category.
  final ValueChanged<int>? onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: config.categoryViewConfig.tabBarHeight,
      child: TabBar(
        labelColor: config.categoryViewConfig.iconColorSelected,
        unselectedLabelColor: config.categoryViewConfig.iconColor,
        dividerColor: Colors.transparent,
        controller: tabController,
        labelPadding: EdgeInsets.zero,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 6,
        ),
        indicator: BoxDecoration(
          color: config.categoryViewConfig.indicatorColor.withValues(
            alpha: 0.14,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: (index) {
          closeSkinToneOverlay();
          if (onCategorySelected != null) {
            onCategorySelected!(index);
          } else {
            pageController.jumpToPage(index);
          }
        },
        tabs: categoryEmojis
            .asMap()
            .entries
            .map<Widget>(
              (item) => Tab(
                icon: Icon(
                  getIconForCategory(
                    config.categoryViewConfig.categoryIcons,
                    item.value.category,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
