import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/story_preview.comp.dart';

/// A contact and the item their bubble opens: the first unseen one in their
/// active story, or its first item once all of it was seen.
class StoryBubbleItem {
  const StoryBubbleItem({required this.story, required this.label});

  final StoryItem story;
  final String label;

  /// Whether the contact's whole story was seen.
  bool get seen => story.seen;
}

/// Groups active story items into one bubble per contact, leaving out the
/// contacts whose story was seen completely unless [includeSeen]. A bubble
/// opens the oldest unseen item. Contacts with something unseen come first,
/// and within that those with newer activity.
List<StoryBubbleItem> buildStoryBubbleItems({
  required Iterable<StoryItem> stories,
  required String Function(StoryItem story) labelFor,
  bool includeSeen = false,
  DateTime? now,
}) {
  final currentTime = now ?? clock.now();
  final bySender = <int, List<StoryItem>>{};
  for (final story in stories) {
    if ((includeSeen || !story.seen) && story.isActiveAt(currentTime)) {
      bySender.putIfAbsent(story.senderId, () => []).add(story);
    }
  }
  for (final stories in bySender.values) {
    stories.sort((a, b) => a.postedAt.compareTo(b.postedAt));
  }
  StoryItem opens(List<StoryItem> stories) =>
      stories.firstWhere((story) => !story.seen, orElse: () => stories.first);
  final groupedStories = bySender.values.toList()
    ..sort((a, b) {
      final aSeen = opens(a).seen;
      if (aSeen != opens(b).seen) return aSeen ? 1 : -1;
      return b.last.postedAt.compareTo(a.last.postedAt);
    });
  return [
    for (final story in groupedStories.map(opens))
      StoryBubbleItem(story: story, label: labelFor(story)),
  ];
}

/// The horizontally scrolling row of stories at the top of the chats.
class StoryBubbleStrip extends StatelessWidget {
  const StoryBubbleStrip({
    required this.items,
    required this.onTap,
    super.key,
  });

  final List<StoryBubbleItem> items;
  final ValueChanged<StoryBubbleItem> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: ListView.separated(
        // Keep this horizontal offset separate from the enclosing chat list.
        key: const PageStorageKey('chat-list-stories'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Semantics(
            button: true,
            label: item.label,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey(item.story.senderId),
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTap(item),
                child: SizedBox(
                  width: 70,
                  child: Column(
                    children: [
                      _StoryBubble(story: item.story),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A circular story preview whose ring drains over the story's lifetime,
/// drawn softer once all of it was seen.
class _StoryBubble extends StatefulWidget {
  const _StoryBubble({required this.story});

  final StoryItem story;

  @override
  State<_StoryBubble> createState() => _StoryBubbleState();
}

class _StoryBubbleState extends State<_StoryBubble> {
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _progressTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.story.expiresAt.difference(clock.now());
    final progress = (remaining.inMilliseconds / storyLifetime.inMilliseconds)
        .clamp(0.0, 1.0);
    return SizedBox.square(
      dimension: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          StoryPreview(
            mediaFile: widget.story.mediaFile,
            width: 58,
            height: 58,
            circle: true,
            faded: widget.story.seen,
          ),
          Positioned.fill(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 1.5,
              strokeCap: StrokeCap.round,
              color: widget.story.seen
                  ? context.color.outline
                  : context.color.primary,
              backgroundColor: context.color.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
