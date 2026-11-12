import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';

/// The bottom bar of the viewer while watching flashbacks: jump to the memory
/// in the memories timeline or share it.
class FlashbackViewerActionsComp extends StatelessWidget {
  const FlashbackViewerActionsComp({
    required this.onShare,
    required this.onJumpTo,
    super.key,
  });

  final VoidCallback onShare;
  final VoidCallback? onJumpTo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _FlashbackAction(
              icon: Icon(
                Icons.grid_view_rounded,
                color: context.appColor(AppColor.mediaForeground),
                size: 20,
              ),
              label: context.lang.memoriesFlashbackJumpTo,
              onTap: onJumpTo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FlashbackAction(
              icon: FaIcon(
                FontAwesomeIcons.paperPlane,
                color: context.appColor(AppColor.mediaForeground),
                size: 17,
              ),
              label: context.lang.galleryActionShare,
              onTap: onShare,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashbackAction extends StatelessWidget {
  const _FlashbackAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColor(AppColor.mediaScrim),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appColor(AppColor.mediaForeground),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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
