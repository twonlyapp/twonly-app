import 'package:flutter/material.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/editor_layer_stack.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/image_item.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers_viewer.dart';
import 'package:video_player/video_player.dart';

/// The media itself with all editor layers stacked on top of it.
///
/// For videos the layers are rendered above the running video, for images the
/// background image is just another layer. The whole stack is wrapped in a
/// [Screenshot] so it can be exported as a single image.
class EditorCanvas extends StatelessWidget {
  const EditorCanvas({
    required this.layerStack,
    required this.screenshotController,
    required this.image,
    required this.pixelRatio,
    required this.onLayersUpdated,
    this.videoController,
    this.bottomOverlay,
    super.key,
  });

  final EditorLayerStack layerStack;
  final ScreenshotController screenshotController;
  final ImageItem image;
  final double pixelRatio;

  /// Called after the user finished interacting with a layer.
  final VoidCallback onLayersUpdated;
  final VideoPlayerController? videoController;

  /// Editor chrome laid over the bottom of the media, outside the [Screenshot]
  /// so it never ends up burnt into what gets sent. Used by the video trimmer.
  final Widget? bottomOverlay;

  bool get _hasVideo =>
      videoController != null && videoController!.value.isInitialized;

  Widget _buildLayers() {
    return Screenshot(
      controller: screenshotController,
      child: LayersViewer(
        layers: layerStack.visible,
        onUpdate: () {
          layerStack.commitPendingEdits();
          onLayersUpdated();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: image.height / pixelRatio,
      width: image.width / pixelRatio,
      child: Stack(
        children: [
          if (_hasVideo)
            Positioned.fill(
              child: Center(
                child: AspectRatio(
                  aspectRatio: videoController!.value.aspectRatio,
                  child: Stack(
                    children: [
                      Positioned.fill(child: VideoPlayer(videoController!)),
                      Positioned.fill(child: _buildLayers()),
                    ],
                  ),
                ),
              ),
            )
          else
            _buildLayers(),
          if (bottomOverlay != null)
            Positioned(left: 0, right: 0, bottom: 0, child: bottomOverlay!),
        ],
      ),
    );
  }
}
