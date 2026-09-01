import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/save_to_gallery.dart';

/// Save to gallery and send, shown below the media.
///
/// When the editor was opened for a single group ([sendToGroup]) the send
/// button sends directly to that group and an additional button opens the
/// contact selection.
class EditorBottomBar extends StatelessWidget {
  const EditorBottomBar({
    required this.mediaService,
    required this.isLoadingImage,
    required this.isSending,
    required this.storeImageAsOriginal,
    required this.onAddMoreRecipients,
    required this.onSend,
    this.sendToGroup,
    super.key,
  });

  final MediaFileService mediaService;
  final Group? sendToGroup;
  final bool isLoadingImage;
  final bool isSending;
  final Future<ScreenshotImageHelper?> Function() storeImageAsOriginal;
  final VoidCallback onAddMoreRecipients;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final hasFixedReceiver = sendToGroup != null;

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SaveToGalleryButton(
            storeImageAsOriginal: storeImageAsOriginal,
            mediaService: mediaService,
            displayButtonLabel: !hasFixedReceiver,
            isLoading: isLoadingImage,
          ),
          if (hasFixedReceiver) ...[
            const SizedBox(width: 10),
            MyButton(
              variant: MyButtonVariant.secondaryMiddle,
              onPressed: onAddMoreRecipients,
              child: const FaIcon(FontAwesomeIcons.userPlus, size: 14),
            ),
          ],
          SizedBox(width: hasFixedReceiver ? 10 : 20),
          IntrinsicWidth(
            child: MyButton(
              variant: MyButtonVariant.primaryMiddle,
              onPressed: isSending ? null : onSend,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSending)
                    const SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.black87),
                      ),
                    )
                  else
                    const FaIcon(FontAwesomeIcons.solidPaperPlane, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    hasFixedReceiver
                        ? substringBy(sendToGroup!.groupName, 15)
                        : context.lang.shareImagedEditorShareWith,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
