import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/emoji_picker.bottom.dart';
import 'package:twonly/src/visual/components/notification_badge.comp.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/action_button.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/editor_layer_stack.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';

/// The editing tools next to the media: add text, drawing and emojis, pick the
/// display time and protect the media.
class EditorSideToolbar extends StatelessWidget {
  const EditorSideToolbar({
    required this.layerStack,
    required this.mediaService,
    required this.onChanged,
    required this.onEditDisplayTime,
    required this.onToggleAudio,
    required this.onToggleRequiresAuth,
    required this.canTrim,
    required this.trimmerVisible,
    required this.onToggleTrimmer,
    super.key,
  });

  final EditorLayerStack layerStack;
  final MediaFileService mediaService;

  /// Called after the layer stack was modified so the editor can rebuild.
  final VoidCallback onChanged;
  final VoidCallback onEditDisplayTime;
  final VoidCallback onToggleAudio;
  final VoidCallback onToggleRequiresAuth;

  /// Whether the clip is far enough along for the cutter to be openable at all;
  /// it needs a player that knows how long the recording is.
  final bool canTrim;
  final bool trimmerVisible;
  final VoidCallback onToggleTrimmer;

  MediaFile get media => mediaService.mediaFile;

  /// How long the receiver may look at the media, `∞` when unlimited and `0`
  /// for videos (they are limited by their own length).
  String get _displayTimeLabel {
    if (media.type == MediaType.video) return '0';
    final limit = media.displayLimitInMilliseconds;
    if (limit == null) return '∞';
    return (limit ~/ 1000).toString();
  }

  IconData get _displayTimeIcon {
    if (media.type != MediaType.video) return Icons.timer_outlined;
    return (media.displayLimitInMilliseconds == null)
        ? Icons.repeat_rounded
        : Icons.repeat_one_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (layerStack.takesOverScreen) return const SizedBox.shrink();

    final canBeEdited = media.type != MediaType.gif;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (canBeEdited)
          ActionButton(
            Icons.text_fields_rounded,
            tooltipText: context.lang.addTextItem,
            onPressed: () {
              layerStack.addTextLayer();
              onChanged();
            },
          ),
        const SizedBox(height: 8),
        if (canBeEdited)
          ActionButton(
            Icons.draw_rounded,
            tooltipText: context.lang.addDrawing,
            onPressed: () {
              layerStack.addDrawLayer();
              onChanged();
            },
          ),
        const SizedBox(height: 8),
        if (canBeEdited)
          ActionButton(
            Icons.add_reaction_outlined,
            tooltipText: context.lang.addEmoji,
            onPressed: () async {
              final layer = await showModalBottomSheet<Layer>(
                context: context,
                backgroundColor: Colors.black,
                builder: (context) => const EmojiPickerBottom(),
              );
              if (layer == null) return;
              layerStack.add(layer);
              onChanged();
            },
          ),
        const SizedBox(height: 8),
        NotificationBadgeComp(
          count: _displayTimeLabel,
          child: ActionButton(
            _displayTimeIcon,
            tooltipText: context.lang.protectAsARealTwonly,
            onPressed: onEditDisplayTime,
          ),
        ),
        if (canTrim) ...[
          const SizedBox(height: 8),
          ActionButton(
            Icons.content_cut_rounded,
            tooltipText: 'Trim video',
            color: trimmerVisible
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            onPressed: onToggleTrimmer,
          ),
        ],
        if (media.type == MediaType.video) ...[
          const SizedBox(height: 8),
          ActionButton(
            (mediaService.removeAudio)
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
            tooltipText: 'Enable Audio in Video',
            color: (mediaService.removeAudio)
                ? Colors.white.withAlpha(160)
                : Colors.white,
            onPressed: onToggleAudio,
          ),
        ],
        if (media.type == MediaType.image) ...[
          const SizedBox(height: 8),
          ActionButton(
            Icons.crop_rotate_outlined,
            tooltipText: 'Crop or rotate image',
            color: Colors.white,
            onPressed: () {
              layerStack.toggleBackgroundEditing();
              onChanged();
            },
          ),
        ],
        const SizedBox(height: 8),
        ActionButton(
          FontAwesomeIcons.shieldHeart,
          tooltipText: context.lang.protectAsARealTwonly,
          color: media.requiresAuthentication
              ? Theme.of(context).colorScheme.primary
              : Colors.white,
          onPressed: onToggleRequiresAuth,
        ),
      ],
    );
  }
}
