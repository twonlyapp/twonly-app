import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> compressImage(
  File sourceFile,
  File destinationFile,
) async {
  final stopwatch = Stopwatch()..start();

  //   // ffmpeg -i input.png -vcodec libwebp -lossless 1 -preset default output.webp

  try {
    var compressedBytes = await FlutterImageCompress.compressWithFile(
      sourceFile.path,
      format: CompressFormat.webp,
      quality: 90,
    );

    if (compressedBytes == null) {
      throw Exception(
        'Could not compress media file: Sending original file.',
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
    Log.warn('$e');
    sourceFile.copySync(destinationFile.path);
  }

  stopwatch.stop();

  Log.info(
    'Compression of the image took: ${stopwatch.elapsedMilliseconds} milliseconds.',
  );
}

Future<void> compressAndOverlayVideo(MediaFileService media) async {
  if (media.tempPath.existsSync()) {
    media.tempPath.deleteSync();
  }
  if (media.ffmpegOutputPath.existsSync()) {
    media.ffmpegOutputPath.deleteSync();
  }

  if (gUser.disableVideoCompression) {
    media.originalPath.copySync(media.tempPath.path);
    return;
  }

  var overLayCommand = '';
  if (media.overlayImagePath.existsSync()) {
    if (Platform.isAndroid) {
      overLayCommand =
          '-i "${media.overlayImagePath.path}" -filter_complex "[1:v]format=yuva420p[ovr_in];[0:v]format=yuv420p[base_in];[ovr_in][base_in]scale2ref=w=rw:h=rh[ovr_out][base_out];[base_out][ovr_out]overlay=0:0"';
    } else {
      overLayCommand =
          '-i "${media.overlayImagePath.path}" -filter_complex "[1:v][0:v]scale2ref=w=ref_w:h=ref_h[ovr][base];[base][ovr]overlay=0:0"';
    }
  }

  final stopwatch = Stopwatch()..start();

  var additionalParams = '';

  if (Platform.isAndroid) {
    additionalParams += ' -c:v libx264';
  }

  var command =
      '-i "${media.originalPath.path}" $overLayCommand  -map "0:a?" $additionalParams -preset veryfast -crf 28 -c:a aac -b:a 64k "${media.ffmpegOutputPath.path}"';

  if (media.removeAudio) {
    command =
        '-i "${media.originalPath.path}" $overLayCommand $additionalParams -preset veryfast -crf 28 -an "${media.ffmpegOutputPath.path}"';
  }

  final session = await FFmpegKit.execute(command);
  final returnCode = await session.getReturnCode();

  if (ReturnCode.isSuccess(returnCode)) {
    media.ffmpegOutputPath.copySync(media.tempPath.path);
    stopwatch.stop();
    Log.info(
      'It took ${stopwatch.elapsedMilliseconds}ms to compress the video',
    );
  } else {
    Log.info(command);
    Log.error('Compression failed for the video with exit code $returnCode.');
    Log.error(await session.getAllLogsAsString());
    // This should not happen, but in case "notify" the user that the video was not send... This is absolutely bad, but
    // better this way then sending an uncompressed media file which potentially is 100MB big :/
    // Hopefully the user will report the strange behavior <3
    await twonlyDB.messagesDao.updateMessagesByMediaId(
      media.mediaFile.mediaId,
      const MessagesCompanion(isDeletedFromSender: Value(true)),
    );
    media.fullMediaRemoval();
    await media.setUploadState(UploadState.uploaded);
  }
}
