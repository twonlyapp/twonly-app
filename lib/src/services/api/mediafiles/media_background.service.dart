import 'dart:async';
import 'package:background_downloader/background_downloader.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/mediafiles/download.service.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/twonly_safe/create_backup.twonly_safe.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> initFileDownloader() async {
  FileDownloader().updates.listen((update) async {
    switch (update) {
      case TaskStatusUpdate():
        if (update.task.taskId.contains('upload_')) {
          await handleUploadStatusUpdate(update);
        }
        if (update.task.taskId.contains('download_')) {
          await handleDownloadStatusUpdate(update);
        }
        if (update.task.taskId.contains('backup')) {
          await handleBackupStatusUpdate(update);
        }
      case TaskProgressUpdate():
        Log.info(
          'Progress update for ${update.task} with progress ${update.progress}',
        );
    }
  });

  await FileDownloader().start();

  try {
    var androidConfig = [];
    if (kDebugMode) {
      androidConfig = [(Config.bypassTLSCertificateValidation, kDebugMode)];
    }
    await FileDownloader().configure(androidConfig: androidConfig);
  } catch (e) {
    Log.error(e);
  }

  if (kDebugMode) {
    FileDownloader().configureNotification(
      running: const TaskNotification(
        'Uploading/Downloading',
        '{filename} ({progress}).',
      ),
      progressBar: true,
    );
  }
}

Future<void> handleUploadStatusUpdate(TaskStatusUpdate update) async {
  final mediaId = update.task.taskId.replaceAll('upload_', '');
  final media = await twonlyDB.mediaFilesDao.getMediaFileById(mediaId);

  if (media == null) {
    Log.error(
      'Got an upload task but no upload media in the media upload database',
    );
    return;
  }

  if (update.status == TaskStatus.complete) {
    if (update.responseStatusCode == 200) {
      Log.info('Upload of ${media.mediaId} success!');

      await twonlyDB.mediaFilesDao.updateMedia(
        media.mediaId,
        const MediaFilesCompanion(
          uploadState: Value(UploadState.uploaded),
        ),
      );

      await twonlyDB.messagesDao.updateMessagesByMediaId(
        media.mediaId,
        const MessagesCompanion(
          ackByServer: Value(true),
        ),
      );
      return;
    }
    Log.error(
      'Got HTTP error ${update.responseStatusCode} for $mediaId',
    );

    if (update.responseStatusCode == 429) {
      await twonlyDB.mediaFilesDao.updateMedia(
        mediaId,
        const MediaFilesCompanion(
          uploadState: Value(UploadState.uploadLimitReached),
        ),
      );
      return;
    }
  }

  Log.info(
    'Background upload failed for $mediaId with status ${update.status}. Trying again.',
  );

  final mediaService = await MediaFileService.fromMedia(media);

  await mediaService.setUploadState(UploadState.uploading);
  // In all other cases just try the upload again...
  await startBackgroundMediaUpload(mediaService);
}
