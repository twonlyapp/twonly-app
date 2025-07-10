import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

Future<void> createThumbnails(String directoryPath) async {
  final directory = Directory(directoryPath);
  final outputDirectory = await getTemporaryDirectory();

  if (await directory.exists()) {
    final List<FileSystemEntity> files = directory.listSync();

    for (var file in files) {
      if (file is File) {
        final String filePath = file.path;
        final String fileExtension = filePath.split('.').last.toLowerCase();

        if (['jpg', 'jpeg', 'png'].contains(fileExtension)) {
          // Create thumbnail for images
          final image = await decodeImageFromList(file.readAsBytesSync());
          final thumbnail = await image.toByteData(format: ImageByteFormat.png);
          final thumbnailFile =
              File('${outputDirectory.path}/${file.uri.pathSegments.last}');
          await thumbnailFile.writeAsBytes(thumbnail!.buffer.asUint8List());
          print('Thumbnail created for image: ${file.uri.pathSegments.last}');
        } else if (['mp4', 'mov', 'avi'].contains(fileExtension)) {
          // Create thumbnail for videos

          print('Thumbnail created for video: ${file.uri.pathSegments.last}');
        }
      }
    }
  } else {
    print('Directory does not exist: $directoryPath');
  }
}

Future createThumbnailsForImage(File file) async {
  final String fileExtension = file.path.split('.').last.toLowerCase();
  if (fileExtension != "png") {
    Log.error("Could not create thumbnail for image. $fileExtension != .png");
    return;
  }

  try {
    final imageBytesCompressed = await FlutterImageCompress.compressWithFile(
      minHeight: 800,
      minWidth: 450,
      file.path,
      format: CompressFormat.png,
      quality: 30,
    );

    if (imageBytesCompressed == null) {
      Log.error("Could not compress the image");
      return;
    }

    File thumbnailFile = getThumbnailPath(file);
    await thumbnailFile.writeAsBytes(imageBytesCompressed);
  } catch (e) {
    Log.error("Could not compress the image got :$e");
  }
}

Future createThumbnailsForVideo(File file) async {
  final String fileExtension = file.path.split('.').last.toLowerCase();
  if (fileExtension != "mp4") {
    Log.error("Could not create thumbnail for video. $fileExtension != .mp4");
    return;
  }

  try {
    await VideoThumbnail.thumbnailFile(
      video: file.path,
      imageFormat: ImageFormat.PNG,
      thumbnailPath: getThumbnailPath(file).path,
      maxWidth: 450,
      quality: 75,
    );
  } catch (e) {
    Log.error("Could not create the video thumbnail: $e");
  }
}

File getThumbnailPath(File file) {
  String originalFileName = file.uri.pathSegments.last;
  String fileNameWithoutExtension = originalFileName.split('.').first;
  String fileExtension = originalFileName.split('.').last;
  if (fileExtension == "mp4") {
    fileExtension = "png";
  }
  String newFileName = '$fileNameWithoutExtension.thumbnail.$fileExtension';
  Directory(file.parent.path).createSync();
  return File(join(file.parent.path, newFileName));
}
