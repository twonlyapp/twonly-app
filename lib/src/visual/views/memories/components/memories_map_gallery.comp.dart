import 'package:flutter/material.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/memories/components/memory_thumbnail.comp.dart';

class MemoriesMapGallery extends StatelessWidget {
  const MemoriesMapGallery({
    required this.controller,
    required this.items,
    required this.onTap,
    required this.isLoading,
    super.key,
  });

  final DraggableScrollableController controller;
  final List<MemoryItem> items;
  final void Function(int index) onTap;
  final bool isLoading;

  static const initialSize = 0.36;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    controller: controller,
    initialChildSize: initialSize,
    minChildSize: 0.16,
    maxChildSize: 0.86,
    snap: true,
    snapSizes: const [0.16, initialSize, 0.86],
    shouldCloseOnMinExtent: false,
    builder: (context, scrollController) => Material(
      color: context.color.surfaceContainer,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      clipBehavior: Clip.antiAlias,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 3,
                  width: 60,
                  decoration: BoxDecoration(
                    color: context.color.outline,
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    context.lang.memoriesMapVisibleCount(items.length),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    context.lang.memoriesMapNoResults,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 8,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 9 / 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => MemoriesThumbnailComp(
                    key: ValueKey(items[index].mediaService.mediaFile.mediaId),
                    galleryItem: items[index],
                    index: index,
                    onTap: () => onTap(index),
                  ),
                  childCount: items.length,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
