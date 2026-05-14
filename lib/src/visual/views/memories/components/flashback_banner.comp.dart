import 'package:flutter/material.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/utils/misc.dart';

class MemoriesFlashbackBannerComp extends StatelessWidget {
  const MemoriesFlashbackBannerComp({
    required this.lastYears,
    required this.onOpenFlashback,
    super.key,
  });

  final Map<int, List<MemoryItem>> lastYears;
  final void Function(List<MemoryItem> items, int index) onOpenFlashback;

  @override
  Widget build(BuildContext context) {
    if (lastYears.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: lastYears.length + 1,
                separatorBuilder: (context, _) => const SizedBox(width: 12),
                itemBuilder: (context, idx) {
                  if (idx == 0) {
                    return const SizedBox.shrink();
                  }
                  idx -= 1;
                  final entry = lastYears.entries.elementAt(idx);
                  final years = entry.key;
                  final items = entry.value;

                  var text = context.lang.memoriesAYearAgo;
                  if (years > 1) {
                    text = context.lang.memoriesXYearsAgo(years);
                  }

                  return GestureDetector(
                    onTap: () => onOpenFlashback(items, 0),
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            items.first.mediaService.storedPath,
                            fit: BoxFit.cover,
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.center,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 8,
                            right: 8,
                            child: Text(
                              text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
