import 'dart:async';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/loader.dart';
import 'package:twonly/src/views/memories/memories_item_thumbnail.dart';
import 'package:twonly/src/views/memories/memories_photo_slider.view.dart';

class MemoriesView extends StatefulWidget {
  const MemoriesView({super.key});

  @override
  State<MemoriesView> createState() => MemoriesViewState();
}

class MemoriesViewState extends State<MemoriesView> {
  int _filesToMigrate = 0;
  List<MemoryItem> galleryItems = [];
  Map<String, List<int>> orderedByMonth = {};
  List<String> months = [];
  StreamSubscription<List<MediaFile>>? messageSub;

  final Map<int, List<MemoryItem>> _galleryItemsLastYears = {};

  @override
  void initState() {
    super.initState();
    unawaited(initAsync());
  }

  @override
  void dispose() {
    messageSub?.cancel();
    super.dispose();
  }

  Future<void> initAsync() async {
    final nonHashedFiles =
        await twonlyDB.mediaFilesDao.getAllNonHashedStoredMediaFiles();
    if (nonHashedFiles.isNotEmpty) {
      setState(() {
        _filesToMigrate = nonHashedFiles.length;
      });
      for (final mediaFile in nonHashedFiles) {
        final mediaService = MediaFileService(mediaFile);
        await mediaService.hashStoredMedia();
        setState(() {
          _filesToMigrate -= 1;
        });
      }
      _filesToMigrate = 0;
    }
    await messageSub?.cancel();
    final msgStream = twonlyDB.mediaFilesDao.watchAllStoredMediaFiles();

    messageSub = msgStream.listen((mediaFiles) async {
      // Group items by month
      orderedByMonth = {};
      months = [];
      var lastMonth = '';
      galleryItems = [];

      final now = clock.now();

      for (final mediaFile in mediaFiles) {
        final mediaService = MediaFileService(mediaFile);
        if (!mediaService.imagePreviewAvailable) continue;
        if (mediaService.mediaFile.type == MediaType.video) {
          if (!mediaService.thumbnailPath.existsSync()) {
            await mediaService.createThumbnail();
          }
        }
        final item = MemoryItem(
          mediaService: mediaService,
          messages: [],
        );
        galleryItems.add(item);
        if (mediaFile.createdAt.month == now.month &&
            mediaFile.createdAt.day == now.day) {
          final diff = now.year - mediaFile.createdAt.year;
          if (diff > 0) {
            if (!_galleryItemsLastYears.containsKey(diff)) {
              _galleryItemsLastYears[diff] = [];
            }
            _galleryItemsLastYears[diff]!.add(item);
          }
        }
      }
      galleryItems.sort(
        (a, b) => b.mediaService.mediaFile.createdAt.compareTo(
          a.mediaService.mediaFile.createdAt,
        ),
      );
      for (var i = 0; i < galleryItems.length; i++) {
        final month = DateFormat('MMMM yyyy')
            .format(galleryItems[i].mediaService.mediaFile.createdAt);
        if (lastMonth != month) {
          lastMonth = month;
          months.add(month);
        }
        orderedByMonth.putIfAbsent(month, () => []).add(i);
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Center(
      child: Text(
        context.lang.memoriesEmpty,
        textAlign: TextAlign.center,
      ),
    );
    if (_filesToMigrate > 0) {
      child = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ThreeRotatingDots(
              size: 40,
              color: context.color.primary,
            ),
            const SizedBox(height: 10),
            Text(
              context.lang.migrationOfMemories(_filesToMigrate),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (galleryItems.isNotEmpty) {
      child = ListView.builder(
        itemCount:
            (months.length * 2) + (_galleryItemsLastYears.isEmpty ? 0 : 1),
        itemBuilder: (context, mIndex) {
          if (_galleryItemsLastYears.isNotEmpty && mIndex == 0) {
            return SizedBox(
              height: 140,
              width: MediaQuery.sizeOf(context).width,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _galleryItemsLastYears.entries.map(
                  (item) {
                    var text = context.lang.memoriesAYearAgo;
                    if (item.key > 1) {
                      text = context.lang.memoriesXYearsAgo(item.key);
                    }
                    return GestureDetector(
                      onTap: () async {
                        await open(context, item.value, 0);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              spreadRadius: -12,
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.hardEdge,
                        height: 150,
                        width: 120,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  item.value.first.mediaService.storedPath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Text(
                                text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  shadows: [
                                    Shadow(
                                      color: Color.fromARGB(122, 0, 0, 0),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            );
          }
          if (_galleryItemsLastYears.isNotEmpty) {
            mIndex -= 1;
          }
          if (mIndex.isEven) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Text(months[(mIndex ~/ 2)]),
            );
          }
          final index = (mIndex - 1) ~/ 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 9 / 16,
            ),
            itemCount: orderedByMonth[months[index]]!.length,
            itemBuilder: (context, gIndex) {
              final gaIndex = orderedByMonth[months[index]]![gIndex];
              return MemoriesItemThumbnail(
                galleryItem: galleryItems[gaIndex],
                onTap: () async {
                  await open(context, galleryItems, gaIndex);
                },
              );
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Memories')),
      body: Scrollbar(
        child: child,
      ),
    );
  }

  Future<void> open(
    BuildContext context,
    List<MemoryItem> galleryItems,
    int index,
  ) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, a1, a2) => MemoriesPhotoSliderView(
          galleryItems: galleryItems,
          initialIndex: index,
        ),
      ),
    ) as bool?;
    if (mounted) setState(() {});
  }
}
