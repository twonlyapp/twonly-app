import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:twonly/src/utils/log.dart';

Future<bool> createThumbnailsForVideo(
  File sourceFile,
  File destinationFile,
) async {
  final stopwatch = Stopwatch()..start();

  if (!sourceFile.existsSync() || sourceFile.lengthSync() == 0) {
    Log.warn('Source video file does not exist or is empty.');
    try {
      if (destinationFile.existsSync()) {
        destinationFile.deleteSync();
      }
    } catch (_) {}
    return false;
  }

  if (destinationFile.existsSync()) {
    if (destinationFile.lengthSync() > 0) {
      return true;
    } else {
      try {
        destinationFile.deleteSync();
      } catch (_) {}
    }
  }

  try {
    final images = await ProVideoEditor.instance.getThumbnails(
      ThumbnailConfigs(
        video: EditorVideo.file(sourceFile),
        outputFormat: ThumbnailFormat.webp,
        timestamps: const [
          Duration.zero,
        ],
        outputSize: const Size(272, 153),
      ),
    );

    if (images.isNotEmpty && images.first.isNotEmpty) {
      stopwatch.stop();
      await destinationFile.writeAsBytes(images.first);
      if (destinationFile.existsSync() && destinationFile.lengthSync() > 0) {
        Log.info(
          'It took ${stopwatch.elapsedMilliseconds}ms to create the video thumbnail.',
        );
        return true;
      }
    }
  } catch (e) {
    Log.error('Error creating video thumbnail: $e');
  }

  Log.warn(
    'Thumbnail creation failed for the video.',
  );
  try {
    if (destinationFile.existsSync()) {
      destinationFile.deleteSync();
    }
  } catch (_) {}
  return false;
}

Future<bool> createThumbnailsForImage(
  File sourceFile,
  File destinationFile,
) async {
  final stopwatch = Stopwatch()..start();

  if (!sourceFile.existsSync() || sourceFile.lengthSync() == 0) {
    Log.warn('Source image file does not exist or is empty.');
    try {
      if (destinationFile.existsSync()) {
        destinationFile.deleteSync();
      }
    } catch (_) {}
    return false;
  }

  if (destinationFile.existsSync()) {
    if (destinationFile.lengthSync() > 0) {
      return true;
    } else {
      try {
        destinationFile.deleteSync();
      } catch (_) {}
    }
  }

  try {
    await FlutterImageCompress.compressAndGetFile(
      sourceFile.absolute.path,
      destinationFile.absolute.path,
      minWidth: 300,
      minHeight: 300,
      quality: 100,
      format: CompressFormat.webp,
    );
    stopwatch.stop();

    if (destinationFile.existsSync() && destinationFile.lengthSync() > 0) {
      Log.info(
        'It took ${stopwatch.elapsedMilliseconds}ms to create the image thumbnail.',
      );
      return true;
    } else {
      Log.error('Compressed image thumbnail is empty or missing.');
      try {
        if (destinationFile.existsSync()) {
          destinationFile.deleteSync();
        }
      } catch (_) {}
      return false;
    }
  } catch (e) {
    Log.error('Error creating image thumbnail: $e');
    try {
      if (destinationFile.existsSync()) {
        destinationFile.deleteSync();
      }
    } catch (_) {}
    return false;
  }
}

Future<bool> createThumbnailsForGif(
  File sourceFile,
  File destinationFile,
) async {
  final stopwatch = Stopwatch()..start();

  if (!sourceFile.existsSync() || sourceFile.lengthSync() == 0) {
    Log.warn('Source GIF file does not exist or is empty.');
    try {
      if (destinationFile.existsSync()) {
        destinationFile.deleteSync();
      }
    } catch (_) {}
    return false;
  }

  if (destinationFile.existsSync()) {
    if (destinationFile.lengthSync() > 0) {
      return true;
    } else {
      try {
        destinationFile.deleteSync();
      } catch (_) {}
    }
  }

  try {
    // For GIFs, we decode the first frame and save it as WebP
    final bytes = await sourceFile.readAsBytes();
    final pngBytes = await compute(_processGifThumbnail, bytes);
    if (pngBytes == null || pngBytes.isEmpty) {
      Log.error('Could not decode GIF for thumbnail.');
      return false;
    }

    final webp = await FlutterImageCompress.compressWithList(
      pngBytes,
      format: CompressFormat.webp,
      quality: 85,
    );
    if (webp.isEmpty) {
      Log.error('GIF thumbnail compression returned empty.');
      return false;
    }

    await destinationFile.writeAsBytes(webp);

    stopwatch.stop();
    if (destinationFile.existsSync() && destinationFile.lengthSync() > 0) {
      Log.info(
        'It took ${stopwatch.elapsedMilliseconds}ms to create the GIF thumbnail.',
      );
      return true;
    } else {
      try {
        if (destinationFile.existsSync()) {
          destinationFile.deleteSync();
        }
      } catch (_) {}
      return false;
    }
  } catch (e) {
    Log.error('Error creating GIF thumbnail: $e');
    try {
      if (destinationFile.existsSync()) {
        destinationFile.deleteSync();
      }
    } catch (_) {}
    return false;
  }
}

Uint8List? _processGifThumbnail(Uint8List bytes) {
  final image = img.decodeGif(bytes);
  if (image == null) return null;

  final thumbnail = img.copyResize(
    image,
    width: image.width > image.height ? 400 : null,
    height: image.height >= image.width ? 400 : null,
  );

  return img.encodePng(thumbnail);
}
