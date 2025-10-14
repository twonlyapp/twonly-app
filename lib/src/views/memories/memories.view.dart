import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/api/media_upload.dart' as send;
import 'package:twonly/src/services/thumbnail.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/memories/memories_item_thumbnail.dart';
import 'package:twonly/src/views/memories/memories_photo_slider.view.dart';

class MemoriesView extends StatefulWidget {
  const MemoriesView({super.key});

  @override
  State<MemoriesView> createState() => MemoriesViewState();
}

class MemoriesViewState extends State<MemoriesView> {
  bool verticalGallery = false;
  List<MemoryItem> galleryItems = [];
  Map<String, List<int>> orderedByMonth = {};
  List<String> months = [];
  StreamSubscription<List<Message>>? messageSub;

  @override
  Future<void> initState() async {
    super.initState();
    await initAsync();
  }

  @override
  Future<void> dispose() async {
    await messageSub?.cancel();
    super.dispose();
  }

  Future<List<MemoryItem>> loadMemoriesDirectory() async {
    final directoryPath = await send.getMediaBaseFilePath('memories');
    final directory = Directory(directoryPath);

    final items = <MemoryItem>[];
    if (directory.existsSync()) {
      final files = directory.listSync();

      for (final file in files) {
        if (file is File) {
          final fileName = file.uri.pathSegments.last;
          File? imagePath;
          File? videoPath;
          late File thumbnailFile;
          if (fileName.contains('.thumbnail.')) {
            continue;
          }
          if (fileName.contains('.png')) {
            imagePath = file;
            thumbnailFile = file;
            // if (!await thumbnailFile.exists()) {
            //   await createThumbnailsForImage(imagePath);
            // }
          } else if (fileName.contains('.mp4')) {
            videoPath = file;
            thumbnailFile = getThumbnailPath(videoPath);
            if (!thumbnailFile.existsSync()) {
              await createThumbnailsForVideo(videoPath);
            }
          } else {
            break;
          }
          final creationDate = file.lastModifiedSync();
          items.add(
            MemoryItem(
              id: int.parse(fileName.split('.')[0]),
              messages: [],
              date: creationDate,
              mirrorVideo: false,
              thumbnailPath: thumbnailFile,
              imagePath: imagePath,
              videoPath: videoPath,
            ),
          );
        }
      }
    }
    return items;
  }

  Future<void> initAsync() async {
    await messageSub?.cancel();
    final msgStream = twonlyDB.messagesDao.getAllStoredMediaFiles();

    messageSub = msgStream.listen((msgs) async {
      final items = await MemoryItem.convertFromMessages(msgs);
      // Group items by month
      orderedByMonth = {};
      months = [];
      var lastMonth = '';
      galleryItems = await loadMemoriesDirectory();
      for (final item in galleryItems) {
        items.remove(
          item.id,
        ); // prefer the stored one and not the saved on in the chat....
      }
      galleryItems += items.values.toList();
      galleryItems.sort((a, b) => b.date.compareTo(a.date));
      for (var i = 0; i < galleryItems.length; i++) {
        final month = DateFormat('MMMM yyyy').format(galleryItems[i].date);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Memories')),
      body: Scrollbar(
        child: (galleryItems.isEmpty)
            ? Center(
                child: Text(
                  context.lang.memoriesEmpty,
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: months.length * 2,
                itemBuilder: (context, mIndex) {
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 9 / 16,
                    ),
                    itemCount: orderedByMonth[months[index]]!.length,
                    itemBuilder: (context, gIndex) {
                      final gaIndex = orderedByMonth[months[index]]![gIndex];
                      return MemoriesItemThumbnail(
                        galleryItem: galleryItems[gaIndex],
                        onTap: () async {
                          await open(context, gaIndex);
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Future<void> open(BuildContext context, int index) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, a1, a2) => MemoriesPhotoSliderView(
          galleryItems: galleryItems,
          initialIndex: index,
          scrollDirection: verticalGallery ? Axis.vertical : Axis.horizontal,
        ),
        // transitionsBuilder: (context, animation, secondaryAnimation, child) {
        //   return child;
        // },
        // transitionDuration: Duration.zero,
        // reverseTransitionDuration: Duration.zero,
      ),
    ) as bool?;
    setState(() {});

    await initAsync();
  }
}
