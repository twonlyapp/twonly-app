import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';

/// A story item's picture standing in for an avatar: the image itself, or
/// the frame taken from a video. Until that file is on the device it is a
/// plain tile, so a story still being downloaded is visible as one.
class StoryPreview extends StatelessWidget {
  const StoryPreview({
    required this.mediaFile,
    required this.width,
    required this.height,
    this.circle = false,
    this.radius = 12,
    this.faded = false,
    this.badge,
    super.key,
  });

  final MediaFile mediaFile;
  final double width;
  final double height;

  /// Clip to a circle instead of a rounded rectangle.
  final bool circle;
  final double radius;

  /// Drawn softer, for a story that has been seen completely.
  final bool faded;

  /// Drawn small over the bottom-right corner, such as whose story it is.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final isVideo = mediaFile.type == MediaType.video;
    final service = MediaFileService(mediaFile);
    // A story stays in its temporary file for as long as it lives; a video
    // is shown by the frame Rust takes from it.
    final source = isVideo ? service.thumbnailPath : service.tempPath;
    final placeholder = ColoredBox(
      color: context.color.surfaceContainerHighest,
      child: Center(
        child: FaIcon(
          isVideo ? FontAwesomeIcons.play : FontAwesomeIcons.image,
          size: width / 3,
          color: context.color.onSurface.withAlpha(90),
        ),
      ),
    );
    Widget picture = Image.file(
      source,
      // A file that appears later, once downloaded, is drawn then.
      key: ValueKey(
        '${mediaFile.mediaId}/${mediaFile.downloadState}/${mediaFile.hasThumbnail}',
      ),
      width: width,
      height: height,
      fit: BoxFit.cover,
      cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
      errorBuilder: (_, _, _) => placeholder,
    );
    picture = circle
        ? ClipOval(child: picture)
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: picture,
          );
    if (faded) picture = Opacity(opacity: 0.5, child: picture);
    final sized = SizedBox(width: width, height: height, child: picture);
    if (badge == null) return sized;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          sized,
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: context.color.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: badge,
            ),
          ),
        ],
      ),
    );
  }
}
