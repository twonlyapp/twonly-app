import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/stories.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/visual/elements/my_icon_button.element.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/story_viewers.bottom_sheet.dart';

/// What the media viewer offers under one of the user's own story items: who
/// has seen it, and taking it down early.
class OwnStoryBottomBar extends StatelessWidget {
  const OwnStoryBottomBar({
    required this.mediaFile,
    required this.onDeleted,
    super.key,
  });

  final MediaFile? mediaFile;

  /// Called once the item is gone, so the viewer can move on.
  final Future<void> Function() onDeleted;

  Future<void> _showViewers(BuildContext context, MediaFile media) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black,
      builder: (context) => StoryViewersBottomSheet(mediaFile: media),
    );
  }

  Future<void> _delete(BuildContext context, MediaFile media) async {
    if (await confirmAndDeleteStoryItem(context, media)) await onDeleted();
  }

  @override
  Widget build(BuildContext context) {
    final media = mediaFile;
    if (media == null) return const SizedBox(height: 55);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StreamBuilder<List<StoryViewer>>(
          stream: twonlyDB.storiesDao.watchStoryViewers(media.mediaId),
          builder: (context, snapshot) {
            final seen = (snapshot.data ?? const [])
                .where((viewer) => viewer.openedAt != null)
                .length;
            return MyIconButton(
              variant: MyIconButtonVariant.secondary,
              onPressed: () => _showViewers(context, media),
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(FontAwesomeIcons.eye, size: 18),
                  const SizedBox(width: 8),
                  Text('$seen'),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        MyIconButton(
          variant: MyIconButtonVariant.secondary,
          onPressed: canDeleteStoryItem(media)
              ? () => _delete(context, media)
              : null,
          icon: const FaIcon(FontAwesomeIcons.trash, size: 18),
        ),
      ],
    );
  }
}
