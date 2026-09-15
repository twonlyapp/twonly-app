import 'dart:io';

import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/mediafiles.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';

class ChatStorageOverviewView extends StatefulWidget {
  const ChatStorageOverviewView({super.key});

  @override
  State<ChatStorageOverviewView> createState() =>
      _ChatStorageOverviewViewState();
}

class _ChatStorageOverviewViewState extends State<ChatStorageOverviewView> {
  late final Stream<List<ChatMediaFiles>> _chatMediaFilesStream;

  @override
  void initState() {
    super.initState();
    _chatMediaFilesStream = twonlyDB.mediaFilesDao.watchMediaFilesByChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsStorageByChat),
      ),
      body: StreamBuilder<List<ChatMediaFiles>>(
        stream: _chatMediaFilesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final summaries =
              (snapshot.data ?? [])
                  .map(_ChatStorageSummary.fromChatMediaFiles)
                  .toList()
                ..sort((a, b) {
                  final sizeComparison = b.totalBytes.compareTo(a.totalBytes);
                  if (sizeComparison != 0) return sizeComparison;
                  return a.group.groupName.toLowerCase().compareTo(
                    b.group.groupName.toLowerCase(),
                  );
                });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TemporaryMediaExplanation(
                text: context.lang.settingsStorageTemporaryMediaDescription,
              ),
              const SizedBox(height: 16),
              if (summaries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    context.lang.settingsStorageNoChats,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                )
              else
                ...summaries.map(
                  (summary) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: AvatarIcon(group: summary.group),
                    title: Text(summary.group.groupName),
                    subtitle: Text(
                      '${context.lang.settingsStorageStoredMediaCount(summary.storedMediaCount)}'
                      ' • '
                      '${context.lang.settingsStorageTemporaryMediaCount(summary.temporaryMediaCount)}',
                    ),
                    trailing: Text(
                      formatBytes(summary.totalBytes),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TemporaryMediaExplanation extends StatelessWidget {
  const _TemporaryMediaExplanation({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ChatStorageSummary {
  const _ChatStorageSummary({
    required this.group,
    required this.storedBytes,
    required this.temporaryBytes,
    required this.storedMediaCount,
    required this.temporaryMediaCount,
  });

  factory _ChatStorageSummary.fromChatMediaFiles(ChatMediaFiles chat) {
    var storedBytes = 0;
    var temporaryBytes = 0;
    var storedMediaCount = 0;
    var temporaryMediaCount = 0;

    for (final mediaFile in chat.mediaFiles) {
      final mediaFileService = MediaFileService(mediaFile);
      final storedSize = _fileSize(mediaFileService.storedPath);
      final temporarySize = _fileSize(mediaFileService.tempPath);

      if (storedSize > 0) {
        storedMediaCount++;
        storedBytes += storedSize;
      }
      if (temporarySize > 0) {
        temporaryMediaCount++;
        temporaryBytes += temporarySize;
      }
    }

    return _ChatStorageSummary(
      group: chat.group,
      storedBytes: storedBytes,
      temporaryBytes: temporaryBytes,
      storedMediaCount: storedMediaCount,
      temporaryMediaCount: temporaryMediaCount,
    );
  }

  final Group group;
  final int storedBytes;
  final int temporaryBytes;
  final int storedMediaCount;
  final int temporaryMediaCount;

  int get totalBytes => storedBytes + temporaryBytes;

  static int _fileSize(File file) {
    try {
      if (!file.existsSync()) return 0;
      return file.lengthSync();
    } on FileSystemException {
      return 0;
    }
  }
}
