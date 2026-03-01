import 'dart:io';
import 'dart:ui';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> createThumbnailsForVideo(
  File sourceFile,
  File destinationFile,
) async {
  final stopwatch = Stopwatch()..start();

  if (destinationFile.existsSync()) {
    return;
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
      'It took ${stopwatch.elapsedMilliseconds}ms to create the thumbnail.',
    );
  } else {
    Log.error(
      'Thumbnail creation failed for the video with exit code.',
    );
  }
}
