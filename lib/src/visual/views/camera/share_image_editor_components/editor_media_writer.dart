import 'dart:typed_data';

import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/editor_layer_stack.dart';

/// Turns the edited layer stack into the files the upload/gallery code expects.
///
/// * images and gifs are written to [MediaFileService.originalPath]
/// * videos keep their original file and get the edits written next to them as
///   [MediaFileService.overlayImagePath]
class EditorMediaWriter {
  EditorMediaWriter({
    required this.mediaService,
    required this.layerStack,
    required this.screenshotController,
    required this.gifSource,
    required this.requestRebuild,
  });

  final MediaFileService mediaService;
  final EditorLayerStack layerStack;
  final ScreenshotController screenshotController;

  /// Gifs are not edited, their bytes are taken as they came in.
  final ScreenshotImageHelper? gifSource;

  /// Rebuilds the editor and waits until the change is on screen. Needed to
  /// hide the per-layer action buttons before taking the screenshot.
  final void Function() requestRebuild;

  MediaFile get media => mediaService.mediaFile;

  /// Renders the visible layers into a single image.
  Future<ScreenshotImageHelper?> captureEditedImage(double pixelRatio) async {
    final unmodified = layerStack.unmodifiedBackgroundImage;
    if (unmodified != null) return unmodified;

    layerStack.setCustomButtonsVisible(visible: false);
    requestRebuild();

    // Make a short delay, so the rebuild does have its effect...
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final image = await screenshotController.capture(pixelRatio: pixelRatio);
    if (image == null) {
      Log.warn('screenshotController did not return image bytes');
      return null;
    }

    layerStack.setCustomButtonsVisible(visible: true);
    requestRebuild();

    return image;
  }

  /// Writes the edited media to disk, replacing any previously written
  /// temporary/overlay files.
  Future<ScreenshotImageHelper?> storeImageAsOriginal(double pixelRatio) async {
    Uint8List? gifBytes;
    ScreenshotImageHelper? image;
    if (media.type == MediaType.gif) {
      gifBytes = await gifSource?.getBytes();
    } else {
      image = await captureEditedImage(pixelRatio);
      if (image != null) {
        await image.getBytes();
      }
    }

    _deleteStaleFiles();

    if (media.type == MediaType.gif) {
      if (gifBytes != null) {
        mediaService.originalPath.writeAsBytesSync(gifBytes.toList());
      }
      return image;
    }

    if (image == null) return null;
    final bytes = await image.getBytes();
    if (bytes == null) {
      Log.warn('imageBytes are empty');
      return null;
    }
    if (media.type == MediaType.image || media.type == MediaType.gif) {
      mediaService.originalPath.writeAsBytesSync(bytes);
    } else if (media.type == MediaType.video) {
      mediaService.overlayImagePath.writeAsBytesSync(bytes);
    } else {
      Log.error('MediaType not supported: ${media.type}');
    }
    return image;
  }

  void _deleteStaleFiles() {
    if (mediaService.overlayImagePath.existsSync()) {
      mediaService.overlayImagePath.deleteSync();
    }
    if (mediaService.tempPath.existsSync()) {
      mediaService.tempPath.deleteSync();
    }
    if (mediaService.originalPath.existsSync() &&
        media.type == MediaType.image) {
      mediaService.originalPath.deleteSync();
    }
  }

  /// Persists the unedited image so it can be restored as a draft in case the
  /// app is restarted while the editor is open.
  Future<void> storeAsDraft(ScreenshotImageHelper screenshotImage) async {
    final imageBytes = await screenshotImage.getBytes();
    mediaService.originalPath.writeAsBytesSync(imageBytes!.toList());
  }
}
