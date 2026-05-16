import 'dart:io';
import 'dart:ui';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:twonly/src/utils/log.dart';

Future<bool> createThumbnailsForVideo(
  File sourceFile,
  File destinationFile,
) async {
  final stopwatch = Stopwatch()..start();

  if (destinationFile.existsSync()) {
    return true;
  }

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

  if (images.isNotEmpty) {
    stopwatch.stop();
    destinationFile.writeAsBytesSync(images.first);
    Log.info(
      'It took ${stopwatch.elapsedMilliseconds}ms to create the video thumbnail.',
    );
    return true;
  } else {
    Log.warn(
      'Thumbnail creation failed for the video.',
    );
    return false;
  }
}

Future<bool> createThumbnailsForImage(
  File sourceFile,
  File destinationFile,
) async {
  final stopwatch = Stopwatch()..start();

  if (destinationFile.existsSync()) {
    return true;
  }

  try {
    final bytes = sourceFile.readAsBytesSync();
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 200,
      minHeight: 200,
      quality: 70,
      format: CompressFormat.webp,
    );

    destinationFile.writeAsBytesSync(result);
    stopwatch.stop();
    Log.info(
      'It took ${stopwatch.elapsedMilliseconds}ms to create the image thumbnail.',
    );
    return true;
  } catch (e) {
    Log.error('Error creating image thumbnail: $e');
    return false;
  }
}

Future<bool> createThumbnailsForGif(
  File sourceFile,
  File destinationFile,
) async {
  final stopwatch = Stopwatch()..start();

  if (destinationFile.existsSync()) {
    return true;
  }

  try {
    // For GIFs, we decode the first frame and save it as WebP
    final bytes = sourceFile.readAsBytesSync();
    final image = img.decodeGif(bytes);
    if (image == null) {
      Log.error('Could not decode GIF for thumbnail.');
      return false;
    }

    final thumbnail = img.copyResize(
      image,
      width: image.width > image.height ? 200 : null,
      height: image.height >= image.width ? 200 : null,
    );

    final pngBytes = img.encodePng(thumbnail);
    final webp = await FlutterImageCompress.compressWithList(
      pngBytes,
      format: CompressFormat.webp,
      quality: 70,
    );
    destinationFile.writeAsBytesSync(webp);

    stopwatch.stop();
    Log.info(
      'It took ${stopwatch.elapsedMilliseconds}ms to create the GIF thumbnail.',
    );
    return true;
  } catch (e) {
    Log.error('Error creating GIF thumbnail: $e');
    return false;
  }
}
