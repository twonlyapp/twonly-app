import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/bridge/stories.dart' as stories;
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/daos/stories.dao.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';

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

/// A delete could overtake an upload still on its way and the item would then
/// arrive after all, so it waits until the upload is done.
bool canDeleteStoryItem(MediaFile mediaFile) =>
    mediaFile.uploadState == UploadState.uploaded;

/// Who has viewed one of the user's story items. Recipients who have not
/// looked at it yet, and how far delivery got, are not the question here.
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
    _viewersSub = twonlyDB.storiesDao
        .watchStoryViewers(widget.mediaFile.mediaId)
        .listen((viewers) {
          if (!mounted) return;
          setState(
            () => _viewers = viewers
                .where((viewer) => viewer.openedAt != null)
                .toList(),
          );
        });
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        color: context.color.surface,
        boxShadow: const [
          BoxShadow(
            blurRadius: 10.9,
            color: Color.fromRGBO(0, 0, 0, 0.1),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 20, bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: Colors.grey,
            ),
            height: 3,
            width: 60,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    context.lang.storyViews(_viewers.length),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: context.lang.storyDelete,
                  onPressed: canDeleteStoryItem(widget.mediaFile)
                      ? _delete
                      : null,
                  icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              children: [
                for (final viewer in _viewers)
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
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          friendlyDateTime(context, viewer.openedAt!),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.color.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
