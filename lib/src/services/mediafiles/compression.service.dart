import 'dart:async';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:video_compress/video_compress.dart';

Future<void> compressImage(
  File sourceFile,
  File destinationFile,
) async {
  final stopwatch = Stopwatch()..start();

  try {
    var compressedBytes = await FlutterImageCompress.compressWithFile(
      sourceFile.path,
      format: CompressFormat.webp,
      quality: 90,
    );

    if (compressedBytes == null) {
      throw Exception(
        'Could not compress media file: $sourceFile. Sending original file.',
      );
    }

    Log.info('Compressed images size in bytes: ${compressedBytes.length}');

    if (compressedBytes.length >= 1 * 1000 * 1000) {
      // if the media file is over 1MB compress it with 60%
      final tmpCompressedBytes = await FlutterImageCompress.compressWithFile(
        sourceFile.path,
        format: CompressFormat.webp,
        quality: 60,
      );
      if (tmpCompressedBytes != null) {
        Log.error(
          'Could not compress media file with 60%: $sourceFile. Sending original 90% compressed file.',
        );
        compressedBytes = tmpCompressedBytes;
      }
    }

    await destinationFile.writeAsBytes(compressedBytes);
  } catch (e) {
    Log.error('$e');
    sourceFile.copySync(destinationFile.path);
  }

  stopwatch.stop();

  Log.info(
    'Compression of the image took: ${stopwatch.elapsedMilliseconds} milliseconds.',
  );
}

Future<void> compressVideo(
  File sourceFile,
  File destinationFile,
) async {
  final stopwatch = Stopwatch()..start();

  MediaInfo? mediaInfo;
  try {
    mediaInfo = await VideoCompress.compressVideo(
      sourceFile.path,
      quality: VideoQuality.Res1280x720Quality,
      includeAudio:
          true, // https://github.com/jonataslaw/VideoCompress/issues/184
    );

    Log.info('Video has now size of ${mediaInfo!.filesize} bytes.');

    if (mediaInfo.filesize! >= 30 * 1000 * 1000) {
      // if the media file is over 20MB compress it with low quality
      mediaInfo = await VideoCompress.compressVideo(
        sourceFile.path,
        quality: VideoQuality.Res960x540Quality,
        includeAudio: true,
      );
    }
  } catch (e) {
    Log.error('during video compression: $e');
  }
  stopwatch.stop();
  Log.info('It took ${stopwatch.elapsedMilliseconds}ms to compress the video');

  if (mediaInfo == null) {
    Log.error('Could not compress video using original video.');
    // as a fall back use the non compressed version
    sourceFile.copySync(destinationFile.path);
  } else {
    await mediaInfo.file!.copy(destinationFile.path);
  }
}
