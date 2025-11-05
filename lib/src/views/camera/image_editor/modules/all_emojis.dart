import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/image_editor/data/layer.dart';

class EmojiPickerBottom extends StatelessWidget {
  const EmojiPickerBottom({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.zero,
        height: 450,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          color: context.color.surfaceContainer,
          boxShadow: [
            BoxShadow(
              blurRadius: 10.9,
              color: context.color.surfaceContainer.withAlpha(25),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.grey,
                ),
                height: 3,
                width: 60,
              ),
              Expanded(
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    Navigator.pop(
                      context,
                      EmojiLayerData(
                        text: emoji.emoji,
                      ),
                    );
                  },
                  // textEditingController: _textFieldController,
                  config: Config(
                    height: 400,
                    locale: Localizations.localeOf(context),
                    viewOrderConfig: const ViewOrderConfig(
                      top: EmojiPickerItem.searchBar,
                      // middle: EmojiPickerItem.emojiView,
                      bottom: EmojiPickerItem.categoryBar,
                    ),
                    emojiTextStyle:
                        TextStyle(fontSize: 24 * (Platform.isIOS ? 1.2 : 1)),
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: context.color.surfaceContainer,
                    ),
                    searchViewConfig: SearchViewConfig(
                      backgroundColor: context.color.surfaceContainer,
                      buttonIconColor: Colors.white,
                    ),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: context.color.surfaceContainer,
                      dividerColor: Colors.white,
                      indicatorColor: context.color.primary,
                      iconColorSelected: context.color.primary,
                      iconColor: context.color.secondary,
                    ),
                    bottomActionBarConfig: BottomActionBarConfig(
                      backgroundColor: context.color.surfaceContainer,
                      buttonColor: context.color.surfaceContainer,
                      buttonIconColor: context.color.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
