import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> createThumbnailsForVideo(
  File sourceFile,
  File destinationFile,
) async {
  final stopwatch = Stopwatch()..start();

  final command =
      '-i "${sourceFile.path}" -ss 00:00:00 -vframes 1 -vf "scale=iw:ih:flags=lanczos" -c:v libwebp  -q:v 100 -compression_level 6 "${destinationFile.path}"';

  final session = await FFmpegKit.execute(command);
  final returnCode = await session.getReturnCode();

  if (ReturnCode.isSuccess(returnCode)) {
    stopwatch.stop();
    Log.info(
      'It took ${stopwatch.elapsedMilliseconds}ms to create the thumbnail.',
    );
  } else {
    Log.info(command);
    Log.error(
      'Thumbnail creation failed for the video with exit code $returnCode.',
    );
    Log.error(await session.getAllLogsAsString());
  }
}
