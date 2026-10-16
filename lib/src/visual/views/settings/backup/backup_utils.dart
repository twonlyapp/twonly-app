import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

Future<bool> promptAndDisableMemoriesBackup(BuildContext context) async {
  final cloudOnlyCount = await twonlyDB.mediaFilesDao
      .getCloudOnlyMemoriesCount();

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
      final allMedias = await (twonlyDB.select(
        twonlyDB.mediaFiles,
      )..where((t) => t.stored.equals(true))).get();
      for (final media in allMedias) {
        final ms = MediaFileService(media);
        if (!ms.storedPath.existsSync()) {
          await ms.fullMediaRemoval();
          await twonlyDB.mediaFilesDao.deleteMediaFile(media.mediaId);
        }
      }
      await twonlyDB.mediaFilesDao.updateAllMediaFiles(
        const MediaFilesCompanion(
          cloudState: Value(CloudState.none),
        ),
      );
      await UserService.update((u) => u.isCloudBackupEnabled = false);
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
