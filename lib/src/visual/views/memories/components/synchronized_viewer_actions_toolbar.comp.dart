import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';

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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (showStoreButton)
              _ToolbarAction(
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
                        size: 18,
                      ),
                label: context.lang.galleryActionSave,
                onTap: isImageSaving ? null : onStore,
              ),
            _ToolbarAction(
              icon: const FaIcon(
                FontAwesomeIcons.download,
                color: Colors.white,
                size: 19,
              ),
              label: context.lang.galleryActionExport,
              onTap: onExport,
            ),
            _ToolbarAction(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.redAccent : Colors.white,
                size: 22,
              ),
              label: isFavorite
                  ? context.lang.galleryActionUnfavorite
                  : context.lang.galleryActionFavorite,
              onTap: onToggleFavorite,
            ),
            _ToolbarAction(
              icon: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 22,
              ),
              label: context.lang.galleryActionDelete,
              onTap: onDelete,
            ),
            _ToolbarAction(
              icon: const FaIcon(
                FontAwesomeIcons.shareNodes,
                color: Colors.white,
                size: 19,
              ),
              label: context.lang.galleryActionShare,
              onTap: onShare,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 24,
                  child: Center(child: icon),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
