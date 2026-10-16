import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/action_button.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/editor_layer_stack.dart';

/// Close, undo and redo, shown above the media.
class EditorTopToolbar extends StatelessWidget {
  const EditorTopToolbar({
    required this.layerStack,
    required this.onClose,
    required this.onChanged,
    super.key,
  });

  final EditorLayerStack layerStack;
  final VoidCallback onClose;

  /// Called after the layer stack was modified so the editor can rebuild.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (layerStack.takesOverScreen) return const SizedBox.shrink();

    return Row(
      children: [
        ActionButton(
          FontAwesomeIcons.xmark,
          tooltipText: context.lang.close,
          onPressed: onClose,
        ),
        Expanded(child: Container()),
        const SizedBox(width: 8),
        ActionButton(
          FontAwesomeIcons.rotateLeft,
          tooltipText: context.lang.undo,
          disable: !layerStack.canUndo,
          onPressed: () {
            layerStack.undo();
            onChanged();
          },
        ),
        const SizedBox(width: 8),
        ActionButton(
          FontAwesomeIcons.rotateRight,
          tooltipText: context.lang.redo,
          disable: !layerStack.canRedo,
          onPressed: () {
            layerStack.redo();
            onChanged();
          },
        ),
        const SizedBox(width: 70),
      ],
    );
  }
}
