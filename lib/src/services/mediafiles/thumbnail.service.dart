import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

Future<void> createThumbnailsForImage(
  File sourceFile,
  File destinationFile,
) async {
  final fileExtension = sourceFile.path.split('.').last.toLowerCase();
  if (fileExtension != 'png') {
    Log.error('Could not create thumbnail for image. $fileExtension != png');
    return;
  }

  try {
    final imageBytesCompressed = await FlutterImageCompress.compressWithFile(
      minHeight: 800,
      minWidth: 450,
      sourceFile.path,
      format: CompressFormat.webp,
      quality: 50,
    );

    if (imageBytesCompressed == null) {
      Log.error('Could not compress the image');
      return;
    }
    await destinationFile.writeAsBytes(imageBytesCompressed);
  } catch (e) {
    Log.error('Could not compress the image got :$e');
  }
}

Future<void> createThumbnailsForVideo(
  File sourceFile,
  File destinationFile,
) async {
  final fileExtension = sourceFile.path.split('.').last.toLowerCase();
  if (fileExtension != 'mp4') {
    Log.error('Could not create thumbnail for video. $fileExtension != .mp4');
    return;
  }

  try {
    await VideoThumbnail.thumbnailFile(
      video: sourceFile.path,
      thumbnailPath: destinationFile.path,
      maxWidth: 450,
      quality: 75,
    );
  } catch (e) {
    Log.error('Could not create the video thumbnail: $e');
  }
}
