import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/stories.dao.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/story_preview.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/last_message_time.comp.dart';
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

  Future<void> _showViewers(OwnStoryItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryViewersBottomSheet(mediaFile: item.mediaFile),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Newest first: the item posted last is the one people see next to the
    // user's name.
    final items = _active.reversed.toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final secondary = TextStyle(
      fontSize: 12,
      color: context.color.onSurface.withAlpha(170),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Text(
            context.lang.storyMine,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                key: ValueKey(item.mediaFile.mediaId),
                onTap: () => _showViewers(item),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StoryPreview(
                      mediaFile: item.mediaFile,
                      width: 72,
                      height: 110,
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 72,
                      child: Row(
                        children: [
                          DefaultTextStyle.merge(
                            style: secondary,
                            child: LastMessageTimeComp(
                              dateTime: item.postedAt,
                            ),
                          ),
                          const Spacer(),
                          FaIcon(
                            FontAwesomeIcons.eye,
                            size: 11,
                            color: secondary.color,
                          ),
                          const SizedBox(width: 4),
                          Text('${item.viewerCount}', style: secondary),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
