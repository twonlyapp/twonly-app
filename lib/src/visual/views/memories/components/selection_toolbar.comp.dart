import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

class MemoriesSelectionToolbarComp extends StatelessWidget {
  const MemoriesSelectionToolbarComp({
    required this.selectedCount,
    required this.areAllSelected,
    required this.areAllFav,
    required this.onSelectAll,
    required this.onExport,
    required this.onFavorite,
    required this.onDelete,
    required this.onClear,
    super.key,
  });

  final int selectedCount;
  final bool areAllSelected;
  final bool areAllFav;
  final VoidCallback onSelectAll;
  final VoidCallback onExport;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.paddingOf(context).bottom + 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: context.color.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: context.color.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Text(
              '$selectedCount',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                areAllSelected ? Icons.deselect : Icons.select_all,
                size: 22,
              ),
              onPressed: onSelectAll,
              tooltip: areAllSelected
                  ? context.lang.galleryDeselectAll
                  : context.lang.gallerySelectAll,
              style: IconButton.styleFrom(
                backgroundColor: context.color.primary.withValues(
                  alpha: 0.1,
                ),
                foregroundColor: context.color.primary,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.file_download_outlined, size: 22),
              onPressed: onExport,
              tooltip: context.lang.galleryExport,
              style: IconButton.styleFrom(
                backgroundColor: context.color.primary.withValues(
                  alpha: 0.1,
                ),
                foregroundColor: context.color.primary,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                areAllFav ? Icons.favorite : Icons.favorite_border,
                size: 22,
                color: areAllFav ? Colors.redAccent : null,
              ),
              onPressed: onFavorite,
              tooltip: areAllFav
                  ? context.lang.galleryUnfavorite
                  : context.lang.galleryFavorite,
              style: IconButton.styleFrom(
                backgroundColor: context.color.primary.withValues(
                  alpha: 0.1,
                ),
                foregroundColor: context.color.primary,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 22),
              onPressed: onDelete,
              tooltip: context.lang.galleryDelete,
              style: IconButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(
                  alpha: 0.1,
                ),
                foregroundColor: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onClear,
              tooltip: context.lang.galleryCancel,
            ),
          ],
        ),
      ),
    );
  }
}
