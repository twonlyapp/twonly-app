import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/bridge/database/stories.dart' as rust_stories;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/misc.dart';
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
      backgroundColor: context.appColor(AppColor.mediaBackground),
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
          stream: watchRustDatabase(
            (control) => rust_stories
                .watchStoryViewers(media: media.mediaId, control: control)
                .map(storyViewers),
          ),
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
          onPressed: () => _delete(context, media),
          icon: const FaIcon(FontAwesomeIcons.trash, size: 18),
        ),
      ],
    );
  }
}
