import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:twonly/src/providers/api/media_send.dart' as send;
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/views/gallery/gallery_item.dart';
import 'package:twonly/src/views/gallery/gallery_item_thumbnail.dart';
import 'package:twonly/src/views/gallery/gallery_photo_view.dart';

class GalleryMainView extends StatefulWidget {
  const GalleryMainView({super.key});

  @override
  State<GalleryMainView> createState() => GalleryMainViewState();
}

class GalleryMainViewState extends State<GalleryMainView> {
  bool verticalGallery = false;
  List<GalleryItem> galleryItems = [];
  Map<String, List<int>> orderedByMonth = {};
  List<String> months = [];
  bool mounted = true;
  StreamSubscription<List<Message>>? messageSub;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  void dispose() {
    mounted = false;
    messageSub?.cancel();
    super.dispose();
  }

  Future<List<GalleryItem>> loadMemoriesDirectory() async {
    final directoryPath = await send.getMediaBaseFilePath("memories");
    final directory = Directory(directoryPath);

    List<GalleryItem> items = [];
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
          items.add(GalleryItem(
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
        twonlyDatabase.messagesDao.getAllStoredMediaFiles();

    messageSub = msgStream.listen((msgs) async {
      Map<int, GalleryItem> items = await GalleryItem.convertFromMessages(msgs);
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
        child: ListView.builder(
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
                return GalleryItemThumbnail(
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
        builder: (context) => GalleryPhotoViewWrapper(
          galleryItems: galleryItems,
          initialIndex: index,
          scrollDirection: verticalGallery ? Axis.vertical : Axis.horizontal,
        ),
      ),
    );
    initAsync();
  }
}
