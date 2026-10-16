import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/elements/my_icon_button.element.dart';

/// Extracted bottom navigation bar widget to provide subtree isolation.
/// Flutter can skip rebuilding this widget when only the parent's unrelated
/// state changes (e.g. progress timer, keyboard insets).
class MediaViewerBottomNavigationBar extends StatelessWidget {
  const MediaViewerBottomNavigationBar({
    required this.currentMedia,
    required this.currentMessage,
    required this.imageSaving,
    required this.imageSaved,
    required this.showShortReactions,
    required this.onSaveToGallery,
    required this.onToggleReactions,
    required this.onMessagePressed,
    required this.onCameraPressed,
    super.key,
  });

  final MediaFileService? currentMedia;
  final Message? currentMessage;
  final bool imageSaving;
  final bool imageSaved;
  final bool showShortReactions;
  final VoidCallback onSaveToGallery;
  final VoidCallback onToggleReactions;
  final VoidCallback onMessagePressed;
  final VoidCallback onCameraPressed;

  /// Pre-built static icon for the emoji grid button so the 4 Lottie
  /// animations are created only once.
  static final Widget _emojiGridIcon = SizedBox(
    width: 30,
    height: 30,
    child: GridView.count(
      crossAxisCount: 2,
      children: List.generate(
        4,
        (index) {
          return SizedBox(
            width: 8,
            height: 8,
            child: Center(
              child: EmojiAnimationComp(
                emoji: EmojiAnimationComp.animatedIconKeys[index],
              ),
            ),
          );
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (currentMedia != null &&
            currentMessage != null &&
            !currentMedia!.mediaFile.requiresAuthentication &&
            currentMedia!.mediaFile.displayLimitInMilliseconds == null)
          MyIconButton(
            variant: MyIconButtonVariant.secondary,
            onPressed: (currentMedia == null || currentMessage == null)
                ? null
                : onSaveToGallery,
            icon: imageSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
                : imageSaved
                ? const Icon(Icons.check)
                : const FaIcon(FontAwesomeIcons.floppyDisk, size: 20),
          ),
        const SizedBox(width: 10),
        IconButton(
          icon: _emojiGridIcon,
          onPressed: onToggleReactions,
          style: ButtonStyle(
            padding: WidgetStateProperty.all<EdgeInsets>(
              const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
          ),
        ),
        const SizedBox(width: 10),
        MyIconButton(
          variant: MyIconButtonVariant.secondary,
          onPressed: onMessagePressed,
          icon: const FaIcon(
            FontAwesomeIcons.message,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        MyIconButton(
          onPressed: onCameraPressed,
          icon: const FaIcon(FontAwesomeIcons.camera, size: 24),
        ),
      ],
    );
  }
}
