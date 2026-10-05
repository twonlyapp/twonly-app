// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

/*
 * Modified version of https://github.com/Fintasys/emoji_picker_flutter
 * MIT License
 * Copyright (c) 2024 Stefan Humm
 */

import 'package:flutter/material.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker_internal_utils.dart';

/// Template class for custom implementation
/// Inhert this class to create your own search view
abstract class SearchView extends StatefulWidget {
  /// Constructor
  const SearchView(this.config, this.state, this.showEmojiView, {super.key});

  /// Config for customizations
  final Config config;

  /// State that holds current emoji data
  final EmojiViewState state;

  /// Return to emoji view
  final VoidCallback showEmojiView;
}

/// Template class for custom implementation
/// Inhert this class to create your own search view state
class SearchViewState<T extends SearchView> extends State<T>
    with SkinToneOverlayStateMixin {
  /// Emoji picker utils
  final utils = EmojiPickerUtils();

  /// Internal utils, used for the cache-backed synchronous fast-path when
  /// loading recent emojis (the public [utils] returns a `Future`).
  final _internalUtils = EmojiPickerInternalUtils();

  /// Focus node for textfield
  final focusNode = FocusNode();

  /// Search results
  final results = List<Emoji>.empty(growable: true);

  /// Last remembered skin tone, applied to skin-tone-capable emoji for display
  /// and selection when [SkinToneConfig.rememberSkinTone] is enabled.
  String? _rememberedSkinTone;

  @override
  void initState() {
    super.initState();
    _loadRememberedSkinTone();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Auto focus textfield
      FocusScope.of(context).requestFocus(focusNode);
      // Load recent emojis initially
      final futureOrRecent = _internalUtils.getRecentEmojis();
      if (futureOrRecent is List<RecentEmoji>) {
        setState(
          () => _updateResults(futureOrRecent.map((e) => e.emoji).toList()),
        );
      } else {
        futureOrRecent.then((value) {
          if (!mounted) return;
          setState(() => _updateResults(value.map((e) => e.emoji).toList()));
        });
      }
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void _loadRememberedSkinTone() {
    if (!widget.config.skinToneConfig.rememberSkinTone) {
      return;
    }
    utils.getRememberedSkinTone().then((tone) {
      if (!mounted || tone == null) {
        return;
      }
      setState(() => _rememberedSkinTone = tone);
    });
  }

  /// On text input changed callback
  void onTextInputChanged(String text) {
    links.clear();
    results.clear();
    utils.searchEmoji(text, widget.state.categoryEmoji).then((value) {
      if (!mounted) return;
      setState(() => _updateResults(value));
    });
  }

  void _updateResults(List<Emoji> emojis) {
    results
      ..clear()
      ..addAll(emojis);
    results.asMap().entries.forEach((e) {
      final displayEmoji = utils.applyDisplaySkinTone(
        e.value,
        widget.config.skinToneConfig,
        _rememberedSkinTone,
      );
      links[displayEmoji.emoji] = LayerLink();
    });
  }

  /// Build emoji cell
  Widget buildEmoji(Emoji emoji, double emojiSize, double emojiBoxSize) {
    // Apply a remembered skin tone for display and selection.
    // Falls back to the base glyph when no tone is remembered.
    final displayEmoji = utils.applyDisplaySkinTone(
      emoji,
      widget.config.skinToneConfig,
      _rememberedSkinTone,
    );
    return addSkinToneTargetIfAvailable(
      hasSkinTone: displayEmoji.hasSkinTone,
      linkKey: displayEmoji.emoji,
      child: EmojiCell.fromConfig(
        emoji: displayEmoji,
        emojiSize: emojiSize,
        emojiBoxSize: emojiBoxSize,
        onEmojiSelected: widget.state.onEmojiSelected,
        config: widget.config,
        onSkinToneDialogRequested:
            (emojiBoxPosition, emoji, emojiSize, category) {
              closeSkinToneOverlay();
              if (!emoji.hasSkinTone || !widget.config.skinToneConfig.enabled) {
                return;
              }
              showSkinToneOverlay(
                emojiBoxPosition,
                emoji,
                emojiSize,
                null,
                widget.config,
                _onSkinTonedEmojiSelected,
                links[emoji.emoji]!,
              );
            },
      ),
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
    final tone = utils.extractSkinTone(emoji);
    if (tone == _rememberedSkinTone) {
      return;
    }
    utils.setRememberedSkinTone(tone);
    setState(() => _rememberedSkinTone = tone);
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('Search View implementation missing');
  }
}

/// Callback for a custom search view.
typedef SearchViewBuilder =
    Widget Function(
      Config config,
      EmojiViewState state,
      VoidCallback showEmojiView,
    );

/// Search view configuration.
class SearchViewConfig {
  /// Constructor.
  const SearchViewConfig({
    this.backgroundColor = const Color(0xFFEBEFF2),
    this.buttonIconColor = Colors.black26,
    this.inputTextStyle,
    this.hintText = 'Search',
    this.hintTextStyle,
    this.customSearchView,
  });

  final Color backgroundColor;
  final Color buttonIconColor;
  final TextStyle? inputTextStyle;
  final String? hintText;
  final TextStyle? hintTextStyle;

  /// Custom search view. Hot reload is not supported.
  final SearchViewBuilder? customSearchView;

  @override
  bool operator ==(Object other) {
    return other is SearchViewConfig &&
        other.backgroundColor == backgroundColor &&
        other.buttonIconColor == buttonIconColor &&
        other.hintText == hintText &&
        other.hintTextStyle == hintTextStyle &&
        other.inputTextStyle == inputTextStyle;
  }

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    buttonIconColor,
    hintText,
    hintTextStyle,
    inputTextStyle,
  );
}

/// Default search implementation.
class DefaultSearchView extends SearchView {
  /// Constructor.
  const DefaultSearchView(
    super.config,
    super.state,
    super.showEmojiView, {
    super.key,
  });

  @override
  DefaultSearchViewState createState() => DefaultSearchViewState();
}

/// State for the default search view.
class DefaultSearchViewState extends SearchViewState<DefaultSearchView> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final emojiSize = widget.config.emojiViewConfig.getEmojiSize(
          constraints.maxWidth,
        );
        final emojiBoxSize = widget.config.emojiViewConfig.getEmojiBoxSize(
          constraints.maxWidth,
        );

        return ColoredBox(
          color: widget.config.searchViewConfig.backgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: SizedBox(
                  height: emojiBoxSize + 8,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      return buildEmoji(
                        results[index],
                        emojiSize,
                        emojiBoxSize,
                      );
                    },
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: widget.showEmojiView,
                    color: widget.config.searchViewConfig.buttonIconColor,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: TextField(
                      onChanged: onTextInputChanged,
                      focusNode: focusNode,
                      style: widget.config.searchViewConfig.inputTextStyle,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.config.searchViewConfig.hintText,
                        hintStyle: widget.config.searchViewConfig.hintTextStyle,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
