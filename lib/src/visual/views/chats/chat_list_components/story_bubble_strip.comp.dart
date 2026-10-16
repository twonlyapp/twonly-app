import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/database/daos/stories.dao.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/story_preview.comp.dart';

/// A contact and the first unseen item in their active story.
class StoryBubbleItem {
  const StoryBubbleItem({required this.story, required this.label});

  final StoryItem story;
  final String label;
}

/// Groups active, unseen story items into one bubble per contact. The bubble
/// opens the oldest unseen item, while contacts with newer activity come first.
List<StoryBubbleItem> buildStoryBubbleItems({
  required Iterable<StoryItem> stories,
  required String Function(StoryItem story) labelFor,
  DateTime? now,
}) {
  final currentTime = now ?? clock.now();
  final unseenBySender = <int, List<StoryItem>>{};
  for (final story in stories) {
    if (!story.seen && story.isActiveAt(currentTime)) {
      unseenBySender.putIfAbsent(story.senderId, () => []).add(story);
    }
  }
  for (final stories in unseenBySender.values) {
    stories.sort((a, b) => a.postedAt.compareTo(b.postedAt));
  }
  final groupedStories = unseenBySender.values.toList()
    ..sort((a, b) => b.last.postedAt.compareTo(a.last.postedAt));
  return [
    for (final stories in groupedStories)
      StoryBubbleItem(story: stories.first, label: labelFor(stories.first)),
  ];
}

/// The horizontally scrolling row of unseen stories at the top of the chats.
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

/// A circular story preview whose ring drains over the story's lifetime.
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
          ),
          Positioned.fill(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 1.5,
              strokeCap: StrokeCap.round,
              color: context.color.primary,
              backgroundColor: context.color.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
