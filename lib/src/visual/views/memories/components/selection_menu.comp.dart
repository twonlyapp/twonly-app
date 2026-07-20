import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/misc.dart';

class MemoriesSelectionMenuComp extends StatelessWidget {
  const MemoriesSelectionMenuComp({
    required this.areAllSelected,
    required this.onSelectAll,
    required this.onExport,
    required this.onFavorite,
    required this.onDeleteCompletely,
    required this.onDeleteLocally,
    super.key,
  });

  final bool areAllSelected;
  final VoidCallback onSelectAll;
  final VoidCallback onExport;
  final VoidCallback onFavorite;
  final VoidCallback onDeleteCompletely;
  final VoidCallback onDeleteLocally;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (val) {
        switch (val) {
          case 'selectAll':
            onSelectAll();
          case 'export':
            onExport();
          case 'favorite':
            onFavorite();
          case 'delete':
            onDeleteCompletely();
          case 'deleteLocal':
            onDeleteLocally();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'selectAll',
          child: Row(
            children: [
              Icon(
                areAllSelected ? Icons.deselect : Icons.select_all,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                areAllSelected
                    ? context.lang.memoriesMenuDeselectAll
                    : context.lang.memoriesMenuSelectAll,
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              const Icon(
                Icons.file_download_outlined,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(context.lang.memoriesMenuExport),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'favorite',
          child: Row(
            children: [
              const Icon(
                Icons.favorite_border,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(context.lang.memoriesMenuFavorite),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_forever_outlined,
                size: 20,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 12),
              Text(
                context.lang.memoriesMenuDelete,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
        ),
        if (userService.currentUser.isCloudBackupEnabled)
          PopupMenuItem(
            value: 'deleteLocal',
            child: Row(
              children: [
                const Icon(
                  Icons.phonelink_erase_outlined,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(context.lang.memoriesMenuDeleteLocal),
              ],
            ),
          ),
      ],
    );
  }
}
