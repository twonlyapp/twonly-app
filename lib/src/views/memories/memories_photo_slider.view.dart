import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/api/media_download.dart' as received;
import 'package:twonly/src/services/api/media_upload.dart' as send;
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/share_image_editor_view.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';
import 'package:twonly/src/views/components/video_player_wrapper.dart';

class MemoriesPhotoSliderView extends StatefulWidget {
  MemoriesPhotoSliderView({
    required this.galleryItems,
    super.key,
    this.loadingBuilder,
    this.minScale,
    this.maxScale,
    this.initialIndex = 0,
    this.scrollDirection = Axis.horizontal,
  }) : pageController = PageController(initialPage: initialIndex);

  final LoadingBuilder? loadingBuilder;
  final dynamic minScale;
  final dynamic maxScale;
  final int initialIndex;
  final PageController pageController;
  final List<MemoryItem> galleryItems;
  final Axis scrollDirection;

  @override
  State<StatefulWidget> createState() {
    return _MemoriesPhotoSliderViewState();
  }
}

class _MemoriesPhotoSliderViewState extends State<MemoriesPhotoSliderView> {
  late int currentIndex = widget.initialIndex;
  final GlobalKey<State<StatefulWidget>> key = GlobalKey();

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Future<void> deleteFile() async {
    final messages = widget.galleryItems[currentIndex].messages;
    final confirmed = await showAlertDialog(
      context,
      context.lang.deleteImageTitle,
      context.lang.deleteImageBody,
    );

    if (!confirmed) return;

    widget.galleryItems[currentIndex].imagePath?.deleteSync();
    widget.galleryItems[currentIndex].videoPath?.deleteSync();
    for (final message in messages) {
      await twonlyDB.messagesDao.updateMessageByMessageId(
        message.messageId,
        const MessagesCompanion(mediaStored: Value(false)),
      );
    }

    widget.galleryItems.removeAt(currentIndex);
    setState(() {});
    await send.purgeSendMediaFiles();
    await received.purgeReceivedMediaFiles();
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> exportFile() async {
    final item = widget.galleryItems[currentIndex];

    try {
      if (item.videoPath != null) {
        await saveVideoToGallery(item.videoPath!.path);
      } else if (item.imagePath != null) {
        final imageBytes = await item.imagePath!.readAsBytes();
        await saveImageToGallery(imageBytes);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.lang.galleryExportSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key,
      direction: DismissDirection.vertical,
      resizeDuration: null,
      onDismissed: (d) {
        Navigator.pop(context, false);
      },
      child: Scaffold(
        backgroundColor: Colors.white.withAlpha(0),
        body: Container(
          color: context.color.surface,
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: <Widget>[
              MediaViewSizing(
                bottomNavigation: Container(
                  color: context.color.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.solidPaperPlane),
                        onPressed: () {
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
                                sharedFromGallery: true,
                                useHighQuality: true,
                              ),
                            ),
                          );
                        },
                        style: ButtonStyle(
                            padding: WidgetStateProperty.all<EdgeInsets>(
                              const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 30),
                            ),
                            backgroundColor: WidgetStateProperty.all<Color>(
                              Theme.of(context).colorScheme.primary,
                            )),
                        label: Text(
                          context.lang.shareImagedEditorSendImage,
                          style: const TextStyle(fontSize: 17),
                        ),
                      ),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    PhotoViewGallery.builder(
                      scrollPhysics: const BouncingScrollPhysics(),
                      builder: _buildItem,
                      itemCount: widget.galleryItems.length,
                      loadingBuilder: widget.loadingBuilder,
                      pageController: widget.pageController,
                      onPageChanged: onPageChanged,
                      scrollDirection: widget.scrollDirection,
                    ),
                    Positioned(
                      right: 5,
                      child: PopupMenuButton<String>(
                        onSelected: (String result) {
                          if (result == 'delete') {
                            deleteFile();
                          }
                          if (result == 'export') {
                            exportFile();
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(context.lang.galleryDelete),
                          ),
                          PopupMenuItem<String>(
                            value: 'export',
                            child: Text(context.lang.galleryExport),
                          ),
                          // PopupMenuItem<String>(
                          //   value: 'details',
                          //   child: Text(context.lang.galleryDetails),
                          // ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final item = widget.galleryItems[index];
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
