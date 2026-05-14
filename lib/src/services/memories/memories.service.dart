import 'dart:async';
import 'dart:collection';

import 'package:clock/clock.dart';
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
    required this.galleryItems,
    required this.months,
    required this.orderedByMonth,
    required this.galleryItemsLastYears,
  });

  final int filesToMigrate;
  final List<MemoryItem> galleryItems;
  final List<String> months;
  final Map<String, List<int>> orderedByMonth;
  final Map<int, List<MemoryItem>> galleryItemsLastYears;

  bool get isLoading => filesToMigrate > 0;
  bool get isEmpty => galleryItems.isEmpty && filesToMigrate == 0;

  MemoriesState copyWith({
    int? filesToMigrate,
    List<MemoryItem>? galleryItems,
    List<String>? months,
    Map<String, List<int>>? orderedByMonth,
    Map<int, List<MemoryItem>>? galleryItemsLastYears,
  }) {
    return MemoriesState(
      filesToMigrate: filesToMigrate ?? this.filesToMigrate,
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

        final mediaFiles =
            await twonlyDB.mediaFilesDao.getMediaFilesByIds(mediaIds);
        final mediaFileMap = {for (final m in mediaFiles) m.mediaId: m};

        final allContacts = await twonlyDB.contactsDao.getAllContacts();
        final contactMap = {for (final c in allContacts) c.userId: c};

        final now = clock.now();
        final tempGalleryItems = <MemoryItem>[];
        final tempGalleryItemsLastYears = <int, List<MemoryItem>>{};

        for (final itemJson in itemList) {
          final map = itemJson as Map<String, dynamic>;
          final mediaId = map['mediaId'] as String?;
          final senderUserId = map['senderUserId'] as int?;
          if (mediaId == null) continue;

          final mediaFile = mediaFileMap[mediaId];
          if (mediaFile == null) continue;

          final mediaService = MediaFileService(mediaFile);
          if (!mediaService.imagePreviewAvailable) continue;

          final contact =
              senderUserId != null ? contactMap[senderUserId] : null;
          final item = MemoryItem(
            mediaService: mediaService,
            messages: [],
            sender: contact,
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

        final tempOrderedByMonth = <String, List<int>>{};
        final tempMonths = <String>[];
        var lastMonth = '';

        for (var i = 0; i < tempGalleryItems.length; i++) {
          final mFile = tempGalleryItems[i].mediaService.mediaFile;
          final month = mFile.createdAtMonth ??
              DateFormat('MMMM yyyy').format(mFile.createdAt);
          if (lastMonth != month) {
            lastMonth = month;
            tempMonths.add(month);
          }
          tempOrderedByMonth.putIfAbsent(month, () => []).add(i);
        }

        for (final list in tempGalleryItemsLastYears.values) {
          list.sort(
            (a, b) => b.mediaService.mediaFile.createdAt
                .compareTo(a.mediaService.mediaFile.createdAt),
          );
        }

        final sortedGalleryItemsLastYears =
            SplayTreeMap<int, List<MemoryItem>>.from(tempGalleryItemsLastYears);

        _cachedState = MemoriesState(
          filesToMigrate: 0,
          galleryItems: tempGalleryItems,
          months: tempMonths,
          orderedByMonth: tempOrderedByMonth,
          galleryItemsLastYears: sortedGalleryItemsLastYears,
        );
      }
    } catch (e) {
      Log.error('Error prewarming memories cache: $e');
    }
  }

  Future<void> _initAsync() async {
    try {
      // 1. Perform Inventory / Migration of non-hashed stored files
      final nonHashedFiles =
          await twonlyDB.mediaFilesDao.getAllNonHashedStoredMediaFiles();
      final unanalyzedFiles =
          await twonlyDB.mediaFilesDao.getAllUnanalyzedStoredMediaFiles();

      final totalToMigrate = nonHashedFiles.length + unanalyzedFiles.length;
      if (totalToMigrate > 0) {
        _updateState(filesToMigrate: totalToMigrate);

        for (final mediaFile in nonHashedFiles) {
          final mediaService = MediaFileService(mediaFile);
          await mediaService.hashStoredMedia();
          _updateState(filesToMigrate: _currentState.filesToMigrate - 1);
        }

        for (final mediaFile in unanalyzedFiles) {
          final mediaService = MediaFileService(mediaFile);
          await mediaService.cropTransparentBorders();
          _updateState(filesToMigrate: _currentState.filesToMigrate - 1);
        }

        _updateState(filesToMigrate: 0);
      }

      // 2. Subscribe to stored media files stream
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
      final now = clock.now();
      final tempGalleryItems = <MemoryItem>[];
      final tempGalleryItemsLastYears = <int, List<MemoryItem>>{};

      // High-performance batch DB fetch for sender attribution via Messages table mapping
      final mediaIds = mediaFiles.map((m) => m.mediaId).toList();
      final allMessages =
          await twonlyDB.messagesDao.getMessagesByMediaIds(mediaIds);
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

      for (final mediaFile in mediaFiles) {
        final mediaService = MediaFileService(mediaFile);
        if (!mediaService.imagePreviewAvailable) continue;

        if (mediaService.mediaFile.type == MediaType.video) {
          if (!mediaService.thumbnailPath.existsSync()) {
            unawaited(mediaService.createThumbnail());
          }
        }

        final senderContact = mediaIdToSenderContact[mediaFile.mediaId];
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
        (a, b) => b.mediaService.mediaFile.createdAt
            .compareTo(a.mediaService.mediaFile.createdAt),
      );

      final tempOrderedByMonth = <String, List<int>>{};
      final tempMonths = <String>[];
      var lastMonth = '';

      // High performance grouping leveraging pre-computed createdAtMonth column
      for (var i = 0; i < tempGalleryItems.length; i++) {
        final mFile = tempGalleryItems[i].mediaService.mediaFile;
        final month = mFile.createdAtMonth ??
            DateFormat('MMMM yyyy').format(mFile.createdAt);
        if (lastMonth != month) {
          lastMonth = month;
          tempMonths.add(month);
        }
        tempOrderedByMonth.putIfAbsent(month, () => []).add(i);
      }

      for (final list in tempGalleryItemsLastYears.values) {
        list.sort(
          (a, b) => b.mediaService.mediaFile.createdAt
              .compareTo(a.mediaService.mediaFile.createdAt),
        );
      }

      final sortedGalleryItemsLastYears =
          SplayTreeMap<int, List<MemoryItem>>.from(tempGalleryItemsLastYears);

      final newState = MemoriesState(
        filesToMigrate: _currentState.filesToMigrate,
        galleryItems: tempGalleryItems,
        months: tempMonths,
        orderedByMonth: tempOrderedByMonth,
        galleryItemsLastYears: sortedGalleryItemsLastYears,
      );

      _cachedState = newState;
      _updateStateWithObject(newState);

      // Persist to KeyValueStore cache asynchronously
      final cacheList = tempGalleryItems
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

  void _updateStateWithObject(MemoriesState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_currentState);
    }
  }

  void _updateState({int? filesToMigrate}) {
    _currentState = _currentState.copyWith(filesToMigrate: filesToMigrate);
    if (!_stateController.isClosed) {
      _stateController.add(_currentState);
    }
  }

  void dispose() {
    _dbSubscription?.cancel();
    _stateController.close();
  }
}
