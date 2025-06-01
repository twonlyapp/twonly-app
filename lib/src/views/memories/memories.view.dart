import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:twonly/src/services/api/media_send.dart' as send;
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/memory_item.model.dart';
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
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  void dispose() {
    messageSub?.cancel();
    super.dispose();
  }

  Future<List<MemoryItem>> loadMemoriesDirectory() async {
    final directoryPath = await send.getMediaBaseFilePath("memories");
    final directory = Directory(directoryPath);

    List<MemoryItem> items = [];
    if (await directory.exists()) {
      final files = directory.listSync();

      for (var file in files) {
        if (file is File) {
          final fileName = file.uri.pathSegments.last;
          File? imagePath;
          File? videoPath;
          if (fileName.contains(".png")) {
            imagePath = file;
          } else if (fileName.contains(".mp4")) {
            videoPath = file;
          } else {
            break;
          }
          final creationDate = await file.lastModified();
          items.add(MemoryItem(
            id: fileName,
            messages: [],
            date: creationDate,
            mirrorVideo: false,
            imagePath: imagePath,
            videoPath: videoPath,
          ));
        }
      }
    }
    return items;
  }

  Future initAsync() async {
    messageSub?.cancel();
    Stream<List<Message>> msgStream =
        twonlyDB.messagesDao.getAllStoredMediaFiles();

    messageSub = msgStream.listen((msgs) async {
      Map<int, MemoryItem> items = await MemoryItem.convertFromMessages(msgs);
      // Group items by month
      orderedByMonth = {};
      months = [];
      String lastMonth = "";
      galleryItems = await loadMemoriesDirectory();
      galleryItems += items.values.toList();
      galleryItems.sort((a, b) => b.date.compareTo(a.date));
      for (var i = 0; i < galleryItems.length; i++) {
        String month = DateFormat('MMMM yyyy').format(galleryItems[i].date);
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
      appBar: AppBar(title: Text('Memories')),
      body: Scrollbar(
        child: (galleryItems.isEmpty)
            ? Center(
                child: Text(
                context.lang.memoriesEmpty,
                textAlign: TextAlign.center,
              ))
            : ListView.builder(
                itemCount: (months.length * 2),
                itemBuilder: (context, mIndex) {
                  if (mIndex % 2 == 0) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(months[(mIndex / 2).toInt()]),
                    );
                  }
                  int index = ((mIndex - 1) / 2).toInt();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 9 / 16,
                    ),
                    itemCount: orderedByMonth[months[index]]!.length,
                    itemBuilder: (context, gIndex) {
                      int gaIndex = orderedByMonth[months[index]]![gIndex];
                      return MemoriesItemThumbnail(
                        galleryItem: galleryItems[gaIndex],
                        onTap: () {
                          open(context, gaIndex);
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  void open(BuildContext context, final int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoriesPhotoSliderView(
          galleryItems: galleryItems,
          initialIndex: index,
          scrollDirection: verticalGallery ? Axis.vertical : Axis.horizontal,
        ),
      ),
    );
    initAsync();
  }
}
