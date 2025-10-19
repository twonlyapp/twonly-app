import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:video_thumbnail/video_thumbnail.dart';


Future<void> createThumbnailForMediaFile(MediaFile media) async {

  switch (media.type) {
    case MediaType.image:
      TODO
      break;
    default:
  }

}

Future<void> createThumbnailsForImage(File file) async {
  final fileExtension = file.path.split('.').last.toLowerCase();
  if (fileExtension != 'png') {
    Log.error('Could not create thumbnail for image. $fileExtension != .png');
    return;
  }

  try {
    final imageBytesCompressed = await FlutterImageCompress.compressWithFile(
      minHeight: 800,
      minWidth: 450,
      file.path,
      format: CompressFormat.webp,
      quality: 50,
    );

    if (imageBytesCompressed == null) {
      Log.error('Could not compress the image');
      return;
    }

    final thumbnailFile = getThumbnailPath(file);
    await thumbnailFile.writeAsBytes(imageBytesCompressed);
  } catch (e) {
    Log.error('Could not compress the image got :$e');
  }
}

Future<void> createThumbnailsForVideo(File file) async {
  final fileExtension = file.path.split('.').last.toLowerCase();
  if (fileExtension != 'mp4') {
    Log.error('Could not create thumbnail for video. $fileExtension != .mp4');
    return;
  }

  try {
    await VideoThumbnail.thumbnailFile(
      video: file.path,
      thumbnailPath: getThumbnailPath(file).path,
      maxWidth: 450,
      quality: 75,
    );
  } catch (e) {
    Log.error('Could not create the video thumbnail: $e');
  }
}

File getThumbnailPath(File file) {
  final originalFileName = file.uri.pathSegments.last;
  final fileNameWithoutExtension = originalFileName.split('.').first;
  var fileExtension = originalFileName.split('.').last;
  if (fileExtension == 'mp4') {
    fileExtension = 'png';
  }
  final newFileName = '$fileNameWithoutExtension.thumbnail.$fileExtension';
  Directory(file.parent.path).createSync();
  return File(join(file.parent.path, newFileName));
}
