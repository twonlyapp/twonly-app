import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/themes/light.dart';

class SynchronizedViewerActionsToolbarComp extends StatelessWidget {
  const SynchronizedViewerActionsToolbarComp({
    required this.isFavorite,
    required this.onShare,
    required this.onExport,
    required this.onToggleFavorite,
    required this.onDelete,
    this.showStoreButton = false,
    this.onStore,
    this.isImageSaving = false,
    super.key,
  });

  final bool isFavorite;
  final VoidCallback onShare;
  final VoidCallback onExport;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;
  final bool showStoreButton;
  final VoidCallback? onStore;
  final bool isImageSaving;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.paddingOf(context).bottom + 24,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showStoreButton) ...[
            IconButton(
              icon: isImageSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const FaIcon(
                      FontAwesomeIcons.floppyDisk,
                      color: Colors.white,
                      size: 20,
                    ),
              onPressed: isImageSaving ? null : onStore,
              tooltip: 'Store media',
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                padding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(width: 16),
          ],
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.fileArrowDown,
              color: Colors.white,
              size: 21,
            ),
            onPressed: onExport,
            tooltip: context.lang.galleryExport,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : Colors.white,
              size: 24,
            ),
            onPressed: onToggleFavorite,
            tooltip: 'Favorite',
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 24,
            ),
            onPressed: onDelete,
            tooltip: context.lang.galleryDelete,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.solidPaperPlane,
              color: primaryColor,
              size: 22,
            ),
            onPressed: onShare,
            tooltip: context.lang.shareImagedEditorSendImage,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
