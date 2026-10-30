import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

Future<bool> promptAndDisableMemoriesBackup(BuildContext context) async {
  final cloudOnlyCount = await rust_mediafiles.cloudOnlyMediaCount(
    directory: MediaFileService.buildDirectoryPath(
      'stored',
      AppEnvironment.supportDir,
    ).path,
    transaction: currentDatabaseSession(),
  );

  if (!context.mounted) return false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.lang.settingsStorageDisableBackupTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                children: formattedText(
                  context,
                  context.lang.settingsStorageDisableBackupBody(
                    cloudOnlyCount,
                  ),
                  textColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: MyButton(
                    variant: MyButtonVariant.secondaryMiddle,
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.lang.galleryCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MyButton(
                    variant: MyButtonVariant.errorMiddle,
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      context.lang.settingsStorageDisableBackupBtn,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (confirmed == true) {
    try {
      await RustApi.disableMemoriesBackup();
      await (() async {
        await rust_mediafiles.finishMemoriesBackupDisable(
          directory: MediaFileService.buildDirectoryPath(
            'stored',
            AppEnvironment.supportDir,
          ).path,
          transaction: currentDatabaseSession(),
        );
      })();
      await UserService.update((u) => u.isCloudBackupEnabled = false);
      memoriesCloudService.limitReached.value = false;
      return true;
    } catch (e) {
      if (context.mounted) {
        showSnackbar(context, e.toString());
      }
      return false;
    }
  }
  return false;
}
