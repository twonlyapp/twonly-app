import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:video_compress/video_compress.dart';

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

  final stopwatch = Stopwatch()..start();

  try {
    final task = VideoRenderData(
      video: EditorVideo.file(media.originalPath),
      // qualityPreset: VideoQualityPreset.p720High,
      imageBytes: media.overlayImagePath.readAsBytesSync(),
      enableAudio: !media.removeAudio,
    );

    final result = await ProVideoEditor.instance.renderVideo(task);
    media.ffmpegOutputPath.writeAsBytesSync(result);

    MediaInfo? mediaInfo;
    try {
      mediaInfo = await VideoCompress.compressVideo(
        media.ffmpegOutputPath.path,
        quality: VideoQuality.Res640x480Quality,
        includeAudio: true,
      );
      Log.info('Video has now size of ${mediaInfo!.filesize} bytes.');
    } catch (e) {
      Log.error('during video compression: $e');
    }

    if (mediaInfo == null) {
      Log.error('Could not compress video using original video.');
      // as a fall back use the non compressed version
      media.ffmpegOutputPath.copySync(media.tempPath.path);
    } else {
      mediaInfo.file!.copySync(media.tempPath.path);
    }

    stopwatch.stop();
    Log.info(
      'It took ${stopwatch.elapsedMilliseconds}ms to compress the video. Reduced from ${media.ffmpegOutputPath.statSync().size} to ${media.tempPath.statSync().size} bytes.',
    );
  } catch (e) {
    Log.error(e);
    // Log.error('Compression failed for the video with exit code $returnCode.');
    // Log.error(await session.getAllLogsAsString());
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
