/*
 * Modified version of https://github.com/Fintasys/emoji_picker_flutter
 * MIT License
 * Copyright (c) 2024 Stefan Humm
 */

import 'package:flutter/material.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';

/// Default EmojiPicker Implementation
class DefaultEmojiPickerView extends EmojiPickerView {
  /// Constructor
  const DefaultEmojiPickerView(
    super.config,
    super.state,
    super.showSearchBar, {
    super.key,
  });

  @override
  State<DefaultEmojiPickerView> createState() => _DefaultEmojiPickerViewState();
}

class _DefaultEmojiPickerViewState extends State<DefaultEmojiPickerView>
    with SingleTickerProviderStateMixin, SkinToneOverlayStateMixin {
  late TabController _tabController;
  late PageController _legacyPageController;
  final _scrollController = ScrollController();
  final _utils = EmojiPickerUtils();

  List<double> _categoryOffsets = const [];
  int _activeCategoryIndex = 0;
  double _emojiBoxSize = 0;
  bool _isNavigatingToCategory = false;

  /// Last remembered skin tone, applied to skin-tone-capable emoji for
  /// display and selection when [SkinToneConfig.rememberSkinTone] is enabled.
  String? _rememberedSkinTone;

  @override
  void initState() {
    // Use controller's current category if available,
    // otherwise use config's initCategory
    final targetCategory =
        widget.state.currentCategory ??
        widget.config.categoryViewConfig.initCategory;

    var initCategory = widget.state.categoryEmoji.indexWhere(
      (element) => element.category == targetCategory,
    );
    if (initCategory == -1) {
      initCategory = 0;
    }
    _tabController = TabController(
      initialIndex: initCategory,
      length: widget.state.categoryEmoji.length,
      vsync: this,
    );
    _activeCategoryIndex = initCategory;
    // Retained for custom category views that still accept the legacy API.
    _legacyPageController = _ContinuousCategoryPageController(
      initialPage: initCategory,
      onPageRequested: _scrollToCategory,
    );
    _scrollController.addListener(_onEmojiScroll);

    // Listen to programmatic category changes from controller
    widget.state.categoryNavigationNotifier.addListener(
      _onCategoryNavigationChanged,
    );

    _loadRememberedSkinTone();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToCategory(initCategory, animate: false);
      }
    });

    super.initState();
  }

  void _loadRememberedSkinTone() {
    if (!widget.config.skinToneConfig.rememberSkinTone) {
      return;
    }
    _utils.getRememberedSkinTone().then((tone) {
      if (!mounted || tone == null) {
        return;
      }
      setState(() => _rememberedSkinTone = tone);
    });
  }

  void _onCategoryNavigationChanged() {
    final targetCategory = widget.state.categoryNavigationNotifier.value;
    if (targetCategory != null) {
      final index = widget.state.categoryEmoji.indexWhere(
        (element) => element.category == targetCategory,
      );
      if (index != -1 && index != _activeCategoryIndex) {
        _scrollToCategory(index);
      }
    }
  }

  @override
  void dispose() {
    widget.state.categoryNavigationNotifier.removeListener(
      _onCategoryNavigationChanged,
    );
    closeSkinToneOverlay();
    _legacyPageController.dispose();
    _scrollController.removeListener(_onEmojiScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final emojiSize = widget.config.emojiViewConfig.getEmojiSize(
          _emojiGridWidth(constraints.maxWidth),
        );
        final emojiBoxSize = widget.config.emojiViewConfig.getEmojiBoxSize(
          _emojiGridWidth(constraints.maxWidth),
        );
        _emojiBoxSize = emojiBoxSize;
        _categoryOffsets = _calculateCategoryOffsets(emojiBoxSize);
        return EmojiContainer(
          color: widget.config.emojiViewConfig.backgroundColor,
          buttonMode: widget.config.emojiViewConfig.buttonMode,
          child: ClipRect(
            child: Column(
              children:
                  [
                    widget.config.viewOrderConfig.top,
                    widget.config.viewOrderConfig.middle,
                    widget.config.viewOrderConfig.bottom,
                  ].map((item) {
                    switch (item) {
                      case EmojiPickerItem.categoryBar:
                        // Category view
                        return _buildCategoryView();
                      case EmojiPickerItem.emojiView:
                        // Emoji view
                        return _buildEmojiView(emojiSize, emojiBoxSize);
                      case EmojiPickerItem.searchBar:
                        // Search Bar
                        return _buildBottomSearchBar();
                    }
                  }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryView() {
    return widget.config.categoryViewConfig.customCategoryView != null
        ? widget.config.categoryViewConfig.customCategoryView!(
            widget.config,
            widget.state,
            _tabController,
            _legacyPageController,
          )
        : DefaultCategoryView(
            widget.config,
            widget.state,
            _tabController,
            _legacyPageController,
            onCategorySelected: _scrollToCategory,
          );
  }

  Widget _buildEmojiView(double emojiSize, double emojiBoxSize) {
    return Flexible(
      child: CustomScrollView(
        key: const Key('emojiScrollView'),
        controller: _scrollController,
        primary: false,
        slivers: _buildCategorySlivers(emojiSize, emojiBoxSize),
      ),
    );
  }

  Widget _buildBottomSearchBar() {
    if (!widget.config.bottomActionBarConfig.enabled) {
      return const SizedBox.shrink();
    }
    return widget.config.bottomActionBarConfig.customBottomActionBar != null
        ? widget.config.bottomActionBarConfig.customBottomActionBar!(
            widget.config,
            widget.state,
            widget.showSearchBar,
          )
        : DefaultBottomActionBar(
            widget.config,
            widget.state,
            widget.showSearchBar,
          );
  }

  double _emojiGridWidth(double availableWidth) {
    final horizontalPadding =
        widget.config.emojiViewConfig.gridPadding.horizontal;
    return (availableWidth - horizontalPadding).clamp(0, availableWidth);
  }

  List<double> _calculateCategoryOffsets(double emojiBoxSize) {
    final viewConfig = widget.config.emojiViewConfig;
    final offsets = <double>[];
    var offset = viewConfig.gridPadding.top;
    for (final entry in widget.state.categoryEmoji.asMap().entries) {
      final categoryEmoji = entry.value;
      offsets.add(offset);
      if (categoryEmoji.category == Category.RECENT &&
          categoryEmoji.emoji.isEmpty) {
        offset += emojiBoxSize;
      } else {
        final rowCount = (categoryEmoji.emoji.length / viewConfig.columns)
            .ceil();
        if (rowCount > 0) {
          offset +=
              rowCount * emojiBoxSize +
              (rowCount - 1) * viewConfig.verticalSpacing;
        }
      }
      if (entry.key < widget.state.categoryEmoji.length - 1) {
        offset += viewConfig.categorySpacing;
      }
    }
    return offsets;
  }

  List<Widget> _buildCategorySlivers(double emojiSize, double emojiBoxSize) {
    final viewConfig = widget.config.emojiViewConfig;
    return [
      if (viewConfig.gridPadding.top > 0)
        SliverToBoxAdapter(child: SizedBox(height: viewConfig.gridPadding.top)),
      for (final entry in widget.state.categoryEmoji.asMap().entries) ...[
        if (entry.value.category == Category.RECENT &&
            entry.value.emoji.isEmpty)
          SliverToBoxAdapter(
            child: SizedBox(height: emojiBoxSize, child: _buildNoRecent()),
          )
        else
          SliverPadding(
            padding: EdgeInsets.only(
              left: viewConfig.gridPadding.left,
              right: viewConfig.gridPadding.right,
            ),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: viewConfig.columns,
                mainAxisSpacing: viewConfig.verticalSpacing,
                crossAxisSpacing: viewConfig.horizontalSpacing,
              ),
              itemCount: entry.value.emoji.length,
              itemBuilder: (context, index) =>
                  _buildEmojiCell(entry.value, index, emojiSize, emojiBoxSize),
            ),
          ),
        if (entry.key < widget.state.categoryEmoji.length - 1 &&
            viewConfig.categorySpacing > 0)
          SliverToBoxAdapter(
            child: SizedBox(
              height: viewConfig.categorySpacing,
            ),
          ),
      ],
      if (viewConfig.gridPadding.bottom > 0)
        SliverToBoxAdapter(
          child: SizedBox(height: viewConfig.gridPadding.bottom),
        ),
    ];
  }

  Widget _buildEmojiCell(
    CategoryEmoji categoryEmoji,
    int index,
    double emojiSize,
    double emojiBoxSize,
  ) {
    // Apply a remembered/default skin tone for display and selection.
    // Falls back to the base glyph when no tone is configured.
    final displayEmoji = _utils.applyDisplaySkinTone(
      categoryEmoji.emoji[index],
      widget.config.skinToneConfig,
      _rememberedSkinTone,
    );
    return addSkinToneTargetIfAvailable(
      hasSkinTone: displayEmoji.hasSkinTone,
      linkKey: categoryEmoji.category.name + displayEmoji.emoji,
      child: EmojiCell.fromConfig(
        emoji: displayEmoji,
        emojiSize: emojiSize,
        emojiBoxSize: emojiBoxSize,
        categoryEmoji: categoryEmoji,
        onEmojiSelected: _onSkinTonedEmojiSelected,
        onSkinToneDialogRequested: _openSkinToneDialog,
        config: widget.config,
      ),
    );
  }

  /// Build Widget for when no recent emoji are available
  Widget _buildNoRecent() {
    return Center(child: widget.config.emojiViewConfig.noRecents);
  }

  void _onEmojiScroll() {
    closeSkinToneOverlay();
    if (_isNavigatingToCategory ||
        _categoryOffsets.isEmpty ||
        !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    var categoryIndex = 0;
    if (position.pixels >= position.maxScrollExtent - 0.5) {
      categoryIndex = _lastCategoryWithEmoji();
    } else {
      final leadingOffset = position.pixels + _emojiBoxSize / 2;
      for (var index = 0; index < _categoryOffsets.length; index++) {
        if (_categoryOffsets[index] <= leadingOffset) {
          categoryIndex = index;
        } else {
          break;
        }
      }
    }
    _setActiveCategory(categoryIndex);
  }

  int _lastCategoryWithEmoji() {
    for (
      var index = widget.state.categoryEmoji.length - 1;
      index >= 0;
      index--
    ) {
      if (widget.state.categoryEmoji[index].emoji.isNotEmpty) {
        return index;
      }
    }
    return 0;
  }

  void _setActiveCategory(int index) {
    if (index == _activeCategoryIndex ||
        index < 0 ||
        index >= widget.state.categoryEmoji.length) {
      return;
    }
    _activeCategoryIndex = index;
    _tabController.animateTo(
      index,
      duration: widget.config.categoryViewConfig.tabIndicatorAnimDuration,
    );
    widget.state.onCategoryChanged?.call(
      widget.state.categoryEmoji[index].category,
    );
  }

  Future<void> _scrollToCategory(int index, {bool animate = true}) async {
    if (index < 0 || index >= widget.state.categoryEmoji.length) {
      return;
    }
    _setActiveCategory(index);
    if (!_scrollController.hasClients || _categoryOffsets.length <= index) {
      return;
    }

    final position = _scrollController.position;
    final target = _categoryOffsets[index].clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _isNavigatingToCategory = true;
    if (animate) {
      await _scrollController.animateTo(
        target,
        duration: widget.config.categoryViewConfig.tabIndicatorAnimDuration,
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
    _isNavigatingToCategory = false;
  }

  void _openSkinToneDialog(
    Offset emojiBoxPosition,
    Emoji emoji,
    double emojiSize,
    CategoryEmoji? categoryEmoji,
  ) {
    closeSkinToneOverlay();
    if (!emoji.hasSkinTone || !widget.config.skinToneConfig.enabled) {
      return;
    }
    showSkinToneOverlay(
      emojiBoxPosition,
      emoji,
      emojiSize,
      categoryEmoji,
      widget.config,
      _onSkinTonedEmojiSelected,
      links[categoryEmoji!.category.name + emoji.emoji]!,
    );
  }

  void _onSkinTonedEmojiSelected(Category? category, Emoji emoji) {
    _rememberSkinToneIfEnabled(emoji);
    widget.state.onEmojiSelected(category, emoji);
    closeSkinToneOverlay();
  }

  /// Persists and re-applies the skin tone of the selected [emoji] when
  /// [SkinToneConfig.rememberSkinTone] is enabled. Selecting a
  /// skin-tone-capable base glyph (no modifier) clears the remembered tone.
  void _rememberSkinToneIfEnabled(Emoji emoji) {
    if (!widget.config.skinToneConfig.rememberSkinTone || !emoji.hasSkinTone) {
      return;
    }
    final tone = _utils.extractSkinTone(emoji);
    if (tone == _rememberedSkinTone) {
      return;
    }
    _utils.setRememberedSkinTone(tone);
    setState(() => _rememberedSkinTone = tone);
  }
}

/// Adapts the previous page-based category navigation API to the continuous
/// scroll view so existing custom category bars keep working.
class _ContinuousCategoryPageController extends PageController {
  _ContinuousCategoryPageController({
    required super.initialPage,
    required this.onPageRequested,
  }) : _currentPage = initialPage;

  final ValueChanged<int> onPageRequested;
  int _currentPage;

  @override
  double? get page => _currentPage.toDouble();

  @override
  void jumpToPage(int page) {
    _currentPage = page;
    onPageRequested(page);
  }

  @override
  Future<void> animateToPage(
    int page, {
    required Duration duration,
    required Curve curve,
  }) async {
    _currentPage = page;
    onPageRequested(page);
  }

  @override
  Future<void> nextPage({required Duration duration, required Curve curve}) =>
      animateToPage(_currentPage + 1, duration: duration, curve: curve);

  @override
  Future<void> previousPage({
    required Duration duration,
    required Curve curve,
  }) => animateToPage(_currentPage - 1, duration: duration, curve: curve);
}
