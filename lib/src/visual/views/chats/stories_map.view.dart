import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/database/stories.dart' as rust_stories;
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/visual/views/chats/media_viewer.view.dart';
import 'package:twonly/src/visual/views/memories/memories_map.view.dart';

/// Seen stories remain on the map until their own deadline. The map itself
/// does not open a story or send receipts; the ordinary viewer does that.
List<StoryItem> locatedStories(Iterable<StoryItem> stories, DateTime now) =>
    stories
        .where(
          (story) =>
              story.isActiveAt(now) &&
              !story.message.isDeletedFromSender &&
              storyLocation(story.message) != null,
        )
        .toList()
      ..sort((a, b) => b.postedAt.compareTo(a.postedAt));

class StoriesMapView extends StatefulWidget {
  const StoriesMapView({super.key});

  @override
  State<StoriesMapView> createState() => _StoriesMapViewState();
}

class _StoriesMapViewState extends State<StoriesMapView> {
  late final StreamController<List<MemoryItem>> _items;
  StreamSubscription<List<StoryItem>>? _subscription;
  List<StoryItem> _stories = [];
  Timer? _expiry;

  @override
  void initState() {
    super.initState();
    _items = StreamController<List<MemoryItem>>.broadcast(
      onListen: () => scheduleMicrotask(_emit),
    );
    final cutoff =
        clock.now().subtract(maxStoryLifetime).millisecondsSinceEpoch ~/ 1000;
    _subscription =
        watchRustDatabase(
          (control) => rust_stories
              .watchReceivedStories(cutoff: cutoff, control: control)
              .map(receivedStoryItems),
        ).listen(
          (stories) {
            _stories = stories;
            _emit();
          },
          onError: (Object error, StackTrace stack) {
            if (!_items.isClosed) _items.addError(error, stack);
          },
        );
  }

  void _emit() {
    if (!mounted || _items.isClosed) return;
    _expiry?.cancel();
    final now = clock.now();
    final active = locatedStories(_stories, now);
    _items.add([
      for (final story in active)
        MemoryItem(
          mediaService: MediaFileService(story.mediaFile),
          messages: [story.message],
        ),
    ]);
    if (active.isNotEmpty) {
      final next = active
          .map((story) => story.expiresAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      _expiry = Timer(next.difference(now), _emit);
    }
  }

  Future<void> _openStories(List<MemoryItem> items, int index) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MediaViewerView.story(
          StorySource.map(
            items.map((item) => item.messages.first).toList(),
            initialMediaId: items[index].mediaService.mediaFile.mediaId,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _expiry?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(_items.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MemoriesMapView.stories(
    storyItems: _items.stream,
    onOpenStories: _openStories,
  );
}
