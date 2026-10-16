import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/stories.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/story_strip.comp.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/story_expiry_timer.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/story_viewers.bottom_sheet.dart';

/// The user's story on their profile: every live item with how long ago it
/// was posted and how many have viewed it. Tapping one lists those viewers.
/// Nothing is shown while the user has no story.
class OwnStoryStrip extends StatefulWidget {
  const OwnStoryStrip({super.key});

  @override
  State<OwnStoryStrip> createState() => _OwnStoryStripState();
}

class _OwnStoryStripState extends State<OwnStoryStrip> {
  StreamSubscription<List<OwnStoryItem>>? _itemsSub;
  List<OwnStoryItem> _items = [];
  final StoryExpiryTimer _expiry = StoryExpiryTimer();

  @override
  void initState() {
    super.initState();
    _itemsSub = twonlyDB.storiesDao.watchOwnStoryItems().listen((items) {
      if (!mounted) return;
      setState(() => _items = items);
      _scheduleExpiry();
    });
  }

  @override
  void dispose() {
    _itemsSub?.cancel();
    _expiry.cancel();
    super.dispose();
  }

  List<OwnStoryItem> get _active {
    final now = clock.now();
    return _items.where((item) => item.isActiveAt(now)).toList();
  }

  void _scheduleExpiry() {
    final oldest = _active.firstOrNull;
    if (oldest == null) {
      _expiry.cancel();
      return;
    }
    _expiry.schedule(
      postedAt: oldest.postedAt,
      now: clock.now(),
      onExpired: () {
        if (!mounted) return;
        setState(() {});
        _scheduleExpiry();
      },
    );
  }

  Future<void> _showViewers(MediaFile mediaFile) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryViewersBottomSheet(mediaFile: mediaFile),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Newest first: the item posted last is the one people see next to the
    // user's name.
    return StoryStrip(
      title: context.lang.storyMine,
      items: [
        for (final item in _active.reversed)
          StoryStripItem(
            mediaFile: item.mediaFile,
            postedAt: item.postedAt,
            viewerCount: item.viewerCount,
          ),
      ],
      onTap: (item) => _showViewers(item.mediaFile),
    );
  }
}
