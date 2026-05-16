import 'dart:async';
import 'dart:collection';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';

class MemoriesState {
  const MemoriesState({
    required this.filesToMigrate,
    required this.totalFilesToMigrate,
    required this.galleryItems,
    required this.months,
    required this.orderedByMonth,
    required this.galleryItemsLastYears,
  });

  final int filesToMigrate;
  final int totalFilesToMigrate;
  final List<MemoryItem> galleryItems;
  final List<String> months;
  final Map<String, List<int>> orderedByMonth;
  final Map<int, List<MemoryItem>> galleryItemsLastYears;

  bool get isLoading => filesToMigrate > 0;
  double get migrationProgress => totalFilesToMigrate > 0
      ? (totalFilesToMigrate - filesToMigrate) / totalFilesToMigrate
      : 0;
  bool get isEmpty => galleryItems.isEmpty && filesToMigrate == 0;

  MemoriesState copyWith({
    int? filesToMigrate,
    int? totalFilesToMigrate,
    List<MemoryItem>? galleryItems,
    List<String>? months,
    Map<String, List<int>>? orderedByMonth,
    Map<int, List<MemoryItem>>? galleryItemsLastYears,
  }) {
    return MemoriesState(
      filesToMigrate: filesToMigrate ?? this.filesToMigrate,
      totalFilesToMigrate: totalFilesToMigrate ?? this.totalFilesToMigrate,
      galleryItems: galleryItems ?? this.galleryItems,
      months: months ?? this.months,
      orderedByMonth: orderedByMonth ?? this.orderedByMonth,
      galleryItemsLastYears:
          galleryItemsLastYears ?? this.galleryItemsLastYears,
    );
  }
}

class MemoriesService {
  MemoriesService() {
    if (_cachedState != null) {
      _currentState = _cachedState!;
    }
    unawaited(_initAsync());
  }

  static MemoriesState? _cachedState;

  final _stateController = StreamController<MemoriesState>.broadcast();
  Stream<MemoriesState> get watchState => _stateController.stream;

  MemoriesState _currentState = const MemoriesState(
    filesToMigrate: 0,
    totalFilesToMigrate: 0,
    galleryItems: [],
    months: [],
    orderedByMonth: {},
    galleryItemsLastYears: {},
  );

  MemoriesState get currentState => _currentState;

  StreamSubscription<List<MediaFile>>? _dbSubscription;

  /// Instantly pre-warms the gallery state from disk cache during app loading
  static Future<void> prewarmCache() async {
    try {
      final data = await KeyValueStore.get('memories_cache');
      if (data != null && data['items'] is List) {
        final itemList = data['items'] as List;
        if (itemList.isEmpty) return;

        final mediaIds = itemList
            .map((e) => (e as Map<String, dynamic>)['mediaId'] as String?)
            .whereType<String>()
            .toList();

        final mediaFiles = await twonlyDB.mediaFilesDao.getMediaFilesByIds(
          mediaIds,
        );

        final allContacts = await twonlyDB.contactsDao.getAllContacts();
        final contactMap = {for (final c in allContacts) c.userId: c};
        final mediaIdToSender = <String, Contact?>{};

        for (final itemJson in itemList) {
          final map = itemJson as Map<String, dynamic>;
          final mediaId = map['mediaId'] as String?;
          final senderUserId = map['senderUserId'] as int?;
          if (mediaId == null) continue;

          mediaIdToSender[mediaId] = senderUserId != null
              ? contactMap[senderUserId]
              : null;
        }

        _cachedState = _computeState(
          mediaFiles: mediaFiles,
          mediaIdToSender: mediaIdToSender,
        );
      }
    } catch (e) {
      Log.error('Error prewarming memories cache: $e');
    }
  }

  static MemoriesState _computeState({
    required List<MediaFile> mediaFiles,
    required Map<String, Contact?> mediaIdToSender,
    int filesToMigrate = 0,
  }) {
    final now = clock.now();
    final tempGalleryItems = <MemoryItem>[];
    final tempGalleryItemsLastYears = <int, List<MemoryItem>>{};

    for (final mediaFile in mediaFiles) {
      final mediaService = MediaFileService(mediaFile);
      if (!mediaService.imagePreviewAvailable) continue;

      final senderContact = mediaIdToSender[mediaFile.mediaId];
      final item = MemoryItem(
        mediaService: mediaService,
        messages: [],
        sender: senderContact,
      );

      tempGalleryItems.add(item);

      if (mediaFile.createdAt.month == now.month &&
          mediaFile.createdAt.day == now.day) {
        final diff = now.year - mediaFile.createdAt.year;
        if (diff > 0) {
          tempGalleryItemsLastYears.putIfAbsent(diff, () => []).add(item);
        }
      }
    }

    // Sort descending by creation date
    tempGalleryItems.sort(
      (a, b) => b.mediaService.mediaFile.createdAt.compareTo(
        a.mediaService.mediaFile.createdAt,
      ),
    );

    final tempOrderedByMonth = <String, List<int>>{};
    final tempMonths = <String>[];
    var lastMonth = '';

    for (var i = 0; i < tempGalleryItems.length; i++) {
      final mFile = tempGalleryItems[i].mediaService.mediaFile;
      final month =
          mFile.createdAtMonth ??
          DateFormat('MMMM yyyy').format(mFile.createdAt);
      if (lastMonth != month) {
        lastMonth = month;
        tempMonths.add(month);
      }
      tempOrderedByMonth.putIfAbsent(month, () => []).add(i);
    }

    for (final list in tempGalleryItemsLastYears.values) {
      list.sort(
        (a, b) => b.mediaService.mediaFile.createdAt.compareTo(
          a.mediaService.mediaFile.createdAt,
        ),
      );
    }

    final sortedGalleryItemsLastYears =
        SplayTreeMap<int, List<MemoryItem>>.from(tempGalleryItemsLastYears);

    return MemoriesState(
      filesToMigrate: filesToMigrate,
      totalFilesToMigrate: filesToMigrate, // Reset total when computing new state? No, keep existing total if migrating.
      galleryItems: tempGalleryItems,
      months: tempMonths,
      orderedByMonth: tempOrderedByMonth,
      galleryItemsLastYears: sortedGalleryItemsLastYears,
    );
  }

  Future<void> _initAsync() async {
    try {
      final pendingFiles = await twonlyDB.mediaFilesDao
          .getAllMediaFilesPendingMigration();

      if (pendingFiles.isNotEmpty) {
        _currentState = _currentState.copyWith(
          filesToMigrate: pendingFiles.length,
          totalFilesToMigrate: pendingFiles.length,
        );
        _notifyState();

        for (final mediaFile in pendingFiles) {
          final mediaService = MediaFileService(mediaFile);

          if (mediaService.mediaFile.storedFileHash == null) {
            await mediaService.hashMediaFile();
          }

          if (!mediaService.mediaFile.hasCropAnalyzed) {
            await mediaService.cropTransparentBorders();
          }

          if (mediaService.mediaFile.sizeInBytes == null) {
            await mediaService.calculateAndSaveSize();
          }

          if (!mediaService.mediaFile.hasThumbnail) {
            if (mediaService.thumbnailPath.existsSync()) {
              await twonlyDB.mediaFilesDao.updateMedia(
                mediaFile.mediaId,
                const MediaFilesCompanion(hasThumbnail: Value(true)),
              );
            } else if (mediaFile.type != MediaType.audio) {
              await mediaService.createThumbnail();
            }
          }
          _updateMigrationCount(_currentState.filesToMigrate - 1);
        }

        _updateMigrationCount(0);
      }

      await _dbSubscription?.cancel();
      _dbSubscription = twonlyDB.mediaFilesDao
          .watchAllStoredMediaFiles()
          .listen(_processMediaFilesStream);
    } catch (e) {
      Log.error('Error initializing MemoriesService: $e');
    }
  }

  Future<void> _processMediaFilesStream(List<MediaFile> mediaFiles) async {
    try {
      final mediaIds = mediaFiles.map((m) => m.mediaId).toList();
      final allMessages = await twonlyDB.messagesDao.getMessagesByMediaIds(
        mediaIds,
      );
      final allContacts = await twonlyDB.contactsDao.getAllContacts();

      final contactMap = {for (final c in allContacts) c.userId: c};
      final mediaIdToSenderContact = <String, Contact>{};

      for (final msg in allMessages) {
        if (msg.mediaId != null && msg.senderId != null) {
          final contact = contactMap[msg.senderId];
          if (contact != null) {
            mediaIdToSenderContact[msg.mediaId!] = contact;
          }
        }
      }

      final newState = _computeState(
        mediaFiles: mediaFiles,
        mediaIdToSender: mediaIdToSenderContact,
        filesToMigrate: _currentState.filesToMigrate,
      ).copyWith(totalFilesToMigrate: _currentState.totalFilesToMigrate);

      for (final item in newState.galleryItems) {
        if (!item.mediaService.mediaFile.hasThumbnail &&
            item.mediaService.mediaFile.type != MediaType.audio) {
          unawaited(item.mediaService.createThumbnail());
        }
      }

      _cachedState = newState;
      _updateState(newState);

      // Persist to KeyValueStore cache asynchronously
      final cacheList = newState.galleryItems
          .map(
            (item) => {
              'mediaId': item.mediaService.mediaFile.mediaId,
              'senderUserId': item.sender?.userId,
            },
          )
          .toList();
      unawaited(KeyValueStore.put('memories_cache', {'items': cacheList}));
    } catch (e) {
      Log.error('Error processing media files stream in MemoriesService: $e');
    }
  }

  void _updateState(MemoriesState newState) {
    _currentState = newState;
    _notifyState();
  }

  void _updateMigrationCount(int filesToMigrate) {
    _currentState = _currentState.copyWith(filesToMigrate: filesToMigrate);
    _notifyState();
  }

  void _notifyState() {
    if (!_stateController.isClosed) {
      _stateController.add(_currentState);
    }
  }

  void dispose() {
    _dbSubscription?.cancel();
    _stateController.close();
  }
}
