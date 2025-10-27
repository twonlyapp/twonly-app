import 'dart:io';
import 'package:twonly/src/utils/log.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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
