import 'dart:convert';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/providers/api/media_send.dart' as send;
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/share_image_editor_view.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';
import 'package:twonly/src/views/components/video_player_wrapper.dart';
import 'package:video_player/video_player.dart';

class GalleryItem {
  GalleryItem({
    required this.id,
    required this.messages,
    required this.date,
    required this.mirrorVideo,
    this.imagePath,
    this.videoPath,
  });
  final String id;
  final bool mirrorVideo;
  final List<Message> messages;
  final DateTime date;
  final File? imagePath;
  final File? videoPath;

  static Future<Map<int, GalleryItem>> convertFromMessages(
      List<Message> messages) async {
    Map<int, GalleryItem> items = {};
    for (final message in messages) {
      bool isSend = message.messageOtherId == null;
      int id = message.mediaUploadId ?? message.messageId;
      final basePath = await send.getMediaFilePath(
        isSend ? message.mediaUploadId! : message.messageId,
        isSend ? "send" : "received",
      );
      File? imagePath;
      File? videoPath;
      if (await File("$basePath.mp4").exists()) {
        videoPath = File("$basePath.mp4");
      } else if (await File("$basePath.png").exists()) {
        imagePath = File("$basePath.png");
      } else {
        continue;
      }
      bool mirrorVideo = false;
      if (videoPath != null) {
        MediaMessageContent content =
            MediaMessageContent.fromJson(jsonDecode(message.contentJson!));
        mirrorVideo = content.mirrorVideo;
      }

      items
          .putIfAbsent(
              id,
              () => GalleryItem(
                  id: id.toString(),
                  messages: [],
                  date: message.sendAt,
                  mirrorVideo: mirrorVideo,
                  imagePath: imagePath,
                  videoPath: videoPath))
          .messages
          .add(message);
    }
    return items;
  }
}

class GalleryItemGrid {
  GalleryItemGrid({
    this.galleryItemIndex,
    this.month,
    this.hide,
  });
  final int? galleryItemIndex;
  final String? month;
  final bool? hide;
}

class GalleryItemThumbnail extends StatefulWidget {
  const GalleryItemThumbnail({
    super.key,
    required this.galleryItem,
    required this.onTap,
  });

  final GalleryItem galleryItem;
  final GestureTapCallback onTap;

  @override
  State<GalleryItemThumbnail> createState() => _GalleryItemThumbnailState();
}

class _GalleryItemThumbnailState extends State<GalleryItemThumbnail> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();

    if (widget.galleryItem.videoPath != null) {
      _controller = VideoPlayerController.file(widget.galleryItem.videoPath!)
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Hero(
        tag: widget.galleryItem.id,
        child: (widget.galleryItem.imagePath != null)
            ? Image.file(widget.galleryItem.imagePath!)
            : Stack(
                children: [
                  if (_controller != null && _controller!.value.isInitialized)
                    Positioned.fill(
                        child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )),
                  if (_controller != null && _controller!.value.isInitialized)
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Text(
                        _controller!.value.isInitialized
                            ? formatDuration(_controller!.value.duration)
                            : '...',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    )
                ],
              ),
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  void dispose() {
    mounted = false;
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
    List<Message> storedMediaFiles =
        await twonlyDatabase.messagesDao.getAllStoredMediaFiles();

    Map<int, GalleryItem> items =
        await GalleryItem.convertFromMessages(storedMediaFiles);

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

  void open(BuildContext context, final int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryPhotoViewWrapper(
          galleryItems: galleryItems,
          // backgroundDecoration: const BoxDecoration(
          //   color: Colors.black,
          // ),
          initialIndex: index,
          scrollDirection: verticalGallery ? Axis.vertical : Axis.horizontal,
        ),
      ),
    );
  }
}

class GalleryPhotoViewWrapper extends StatefulWidget {
  GalleryPhotoViewWrapper({
    super.key,
    this.loadingBuilder,
    this.backgroundDecoration,
    this.minScale,
    this.maxScale,
    this.initialIndex = 0,
    required this.galleryItems,
    this.scrollDirection = Axis.horizontal,
  }) : pageController = PageController(initialPage: initialIndex);

  final LoadingBuilder? loadingBuilder;
  final BoxDecoration? backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;
  final int initialIndex;
  final PageController pageController;
  final List<GalleryItem> galleryItems;
  final Axis scrollDirection;

  @override
  State<StatefulWidget> createState() {
    return _GalleryPhotoViewWrapperState();
  }
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
  late int currentIndex = widget.initialIndex;

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: widget.backgroundDecoration,
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: <Widget>[
            MediaViewSizing(
              bottomNavigation: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    icon: FaIcon(FontAwesomeIcons.solidPaperPlane),
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShareImageEditorView(
                            videoFilePath:
                                widget.galleryItems[currentIndex].videoPath,
                            imageBytes: widget
                                .galleryItems[currentIndex].imagePath
                                ?.readAsBytes(),
                            mirrorVideo: false,
                            useHighQuality: true,
                          ),
                        ),
                      );
                    },
                    style: ButtonStyle(
                        padding: WidgetStateProperty.all<EdgeInsets>(
                          EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                        ),
                        backgroundColor: WidgetStateProperty.all<Color>(
                          Theme.of(context).colorScheme.primary,
                        )),
                    label: Text(
                      context.lang.shareImagedEditorSendImage,
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ],
              ),
              child: PhotoViewGallery.builder(
                scrollPhysics: const BouncingScrollPhysics(),
                builder: _buildItem,
                itemCount: widget.galleryItems.length,
                loadingBuilder: widget.loadingBuilder,
                backgroundDecoration: widget.backgroundDecoration,
                pageController: widget.pageController,
                onPageChanged: onPageChanged,
                scrollDirection: widget.scrollDirection,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final GalleryItem item = widget.galleryItems[index];
    return item.videoPath != null
        ? PhotoViewGalleryPageOptions.customChild(
            child: VideoPlayerWrapper(
              videoPath: item.videoPath!,
              mirrorVideo: item.mirrorVideo,
            ),
            // childSize: const Size(300, 300),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4.1,
            heroAttributes: PhotoViewHeroAttributes(tag: item.id),
          )
        : PhotoViewGalleryPageOptions(
            imageProvider: FileImage(item.imagePath!),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4.1,
            heroAttributes: PhotoViewHeroAttributes(tag: item.id),
          );
  }
}
