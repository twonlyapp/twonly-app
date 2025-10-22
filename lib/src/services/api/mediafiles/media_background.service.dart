import 'dart:async';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:twonly/src/services/api/mediafiles/download.service.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
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
