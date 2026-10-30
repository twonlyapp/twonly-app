import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/bridge/database/stories.dart' as rust_stories;
import 'package:twonly/core/bridge/stories.dart' as stories;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/components/story_preview.comp.dart';

/// Asks, then takes one of the user's story items down for everybody.
/// Returns whether it is gone.
Future<bool> confirmAndDeleteStoryItem(
  BuildContext context,
  MediaFile mediaFile,
) async {
  final confirmed = await showAlertDialog(
    context,
    context.lang.storyDeleteTitle,
    context.lang.storyDeleteBody,
    customOk: context.lang.storyDelete,
  );
  if (!confirmed) return false;
  try {
    await stories.deleteStoryItem(mediaId: mediaFile.mediaId);
    return true;
  } catch (e) {
    Log.error('Could not delete the story item: $e');
    if (context.mounted) showSnackbar(context, context.lang.storyDeleteFailed);
    return false;
  }
}

/// Lists who has seen one of the user's story items. Resolves to whether the
/// user asked to see the item itself again.
Future<bool> showStoryViewers(BuildContext context, MediaFile mediaFile) async {
  final showAgain = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StoryViewersBottomSheet(mediaFile: mediaFile),
  );
  return showAgain ?? false;
}

/// Who has opened a story item, most recent first. Developers see everybody
/// it was sent to instead, with when it was received next to when it was
/// opened.
class StoryViewersBottomSheet extends StatefulWidget {
  const StoryViewersBottomSheet({required this.mediaFile, super.key});

  final MediaFile mediaFile;

  @override
  State<StoryViewersBottomSheet> createState() =>
      _StoryViewersBottomSheetState();
}

class _StoryViewersBottomSheetState extends State<StoryViewersBottomSheet> {
  StreamSubscription<List<StoryViewer>>? _viewersSub;
  List<StoryViewer> _viewers = [];

  @override
  void initState() {
    super.initState();
    _viewersSub =
        watchRustDatabase(
          (control) => rust_stories
              .watchStoryViewers(
                media: widget.mediaFile.mediaId,
                control: control,
              )
              .map(storyViewers),
        ).listen(
          (
            viewers,
          ) {
            if (!mounted) return;
            setState(() => _viewers = viewers);
          },
        );
  }

  @override
  void dispose() {
    _viewersSub?.cancel();
    super.dispose();
  }

  Future<void> _delete() async {
    final deleted = await confirmAndDeleteStoryItem(context, widget.mediaFile);
    if (deleted && mounted) Navigator.pop(context);
  }

  /// Most recently opened first, then most recently received, then those it
  /// has not reached yet.
  static int _latestFirst(StoryViewer a, StoryViewer b) {
    int newestFirst(DateTime? x, DateTime? y) {
      if (x == null) return y == null ? 0 : 1;
      if (y == null) return -1;
      return y.compareTo(x);
    }

    final opened = newestFirst(a.openedAt, b.openedAt);
    return opened != 0 ? opened : newestFirst(a.receivedAt, b.receivedAt);
  }

  @override
  Widget build(BuildContext context) {
    final showReceipts = userService.currentUser.isDeveloper;
    final opened = _viewers.where((viewer) => viewer.openedAt != null);
    final listed = (showReceipts ? [..._viewers] : opened.toList())
      ..sort(_latestFirst);
    return DraggableScrollableSheet(
      maxChildSize: 0.9,
      expand: false,
      builder: (context, controller) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          color: context.color.surface,
          boxShadow: [
            BoxShadow(
              blurRadius: 10.9,
              color: context.color.shadow.withValues(alpha: 0.1),
            ),
          ],
        ),
        // The header scrolls with the sheet's controller as well, so the
        // sheet is pulled up or down from its handle.
        child: CustomScrollView(
          controller: controller,
          // A short list still has to move the sheet.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            PinnedHeaderSliver(child: _header(opened.length)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                30,
                0,
                30,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverList.builder(
                itemCount: listed.length,
                itemBuilder: (context, index) =>
                    _viewerRow(listed[index], showReceipts: showReceipts),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(int views) => ColoredBox(
    color: context.color.surface,
    child: Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 20, bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: context.color.outline,
          ),
          height: 3,
          width: 60,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Row(
            children: [
              IconButton(
                tooltip: context.lang.storyShowAgain,
                onPressed: () => Navigator.pop(context, true),
                icon: StoryPreview(
                  mediaFile: widget.mediaFile,
                  width: 24,
                  height: 24,
                  radius: 6,
                ),
              ),
              Expanded(
                child: Text(
                  context.lang.storyViews(views),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: context.lang.storyDelete,
                onPressed: _delete,
                icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _viewerRow(StoryViewer viewer, {required bool showReceipts}) =>
      Padding(
        key: ValueKey(viewer.message.messageId),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AvatarIcon(contactId: viewer.contact.userId),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                getContactDisplayName(viewer.contact),
                style: const TextStyle(fontSize: 17),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (showReceipts)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _receipt(
                    FontAwesomeIcons.check,
                    context.lang.received,
                    viewer.receivedAt,
                  ),
                  const SizedBox(height: 2),
                  _receipt(
                    FontAwesomeIcons.eye,
                    context.lang.opened,
                    viewer.openedAt,
                  ),
                ],
              )
            else
              Text(
                formatRelativeDateTime(context, viewer.openedAt),
                style: _secondary,
              ),
          ],
        ),
      );

  Widget _receipt(FaIconData icon, String label, DateTime? at) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      FaIcon(icon, size: 10, color: _secondary.color, semanticLabel: label),
      const SizedBox(width: 6),
      Text(formatRelativeDateTime(context, at), style: _secondary),
    ],
  );

  TextStyle get _secondary => TextStyle(
    fontSize: 12,
    color: context.color.onSurface.withAlpha(150),
  );
}
