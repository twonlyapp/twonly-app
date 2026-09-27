import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/story_preview.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/last_message_time.comp.dart';

/// One item in a [StoryStrip].
class StoryStripItem {
  const StoryStripItem({
    required this.mediaFile,
    required this.postedAt,
    required this.viewerCount,
  });

  final MediaFile mediaFile;
  final DateTime postedAt;
  final int viewerCount;
}

/// The user's story as a row of previews, newest first, each with how long
/// ago it was posted and how many have viewed it. Nothing is shown while
/// there are no [items].
class StoryStrip extends StatelessWidget {
  const StoryStrip({
    required this.title,
    required this.items,
    required this.onTap,
    super.key,
  });

  final String title;

  /// Newest first.
  final List<StoryStripItem> items;
  final ValueChanged<StoryStripItem> onTap;

  @override
  Widget build(BuildContext context) {
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
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
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
                onTap: () => onTap(item),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Gives way to the view count on a long label.
                          Flexible(
                            child: DefaultTextStyle.merge(
                              style: secondary,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              child: LastMessageTimeComp(
                                dateTime: item.postedAt,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 4),
                              FaIcon(
                                FontAwesomeIcons.eye,
                                size: 11,
                                color: secondary.color,
                              ),
                              const SizedBox(width: 4),
                              Text('${item.viewerCount}', style: secondary),
                            ],
                          ),
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
