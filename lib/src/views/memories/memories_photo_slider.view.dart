import 'package:drift/drift.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/services/api/media_received.dart' as received;
import 'package:twonly/src/services/api/media_send.dart' as send;
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/share_image_editor_view.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';
import 'package:twonly/src/views/components/video_player_wrapper.dart';
import 'package:twonly/src/model/memory_item.model.dart';

class MemoriesPhotoSliderView extends StatefulWidget {
  MemoriesPhotoSliderView({
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
  final List<MemoryItem> galleryItems;
  final Axis scrollDirection;

  @override
  State<StatefulWidget> createState() {
    return _MemoriesPhotoSliderViewState();
  }
}

class _MemoriesPhotoSliderViewState extends State<MemoriesPhotoSliderView> {
  late int currentIndex = widget.initialIndex;

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Future deleteFile() async {
    List<Message> messages = widget.galleryItems[currentIndex].messages;
    bool confirmed = await showAlertDialog(
        context, "Are you sure?", "The image will be irrevocably deleted.");

    if (!confirmed) return;

    widget.galleryItems[currentIndex].imagePath?.deleteSync();
    widget.galleryItems[currentIndex].videoPath?.deleteSync();
    for (final message in messages) {
      await twonlyDB.messagesDao.updateMessageByMessageId(
        message.messageId,
        MessagesCompanion(mediaStored: Value(false)),
      );
    }

    widget.galleryItems.removeAt(currentIndex);
    setState(() {});
    await send.purgeSendMediaFiles();
    await received.purgeReceivedMediaFiles();
    if (context.mounted) {
      Navigator.pop(context, true);
    }
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
              child: Stack(
                children: [
                  PhotoViewGallery.builder(
                    scrollPhysics: const BouncingScrollPhysics(),
                    builder: _buildItem,
                    itemCount: widget.galleryItems.length,
                    loadingBuilder: widget.loadingBuilder,
                    backgroundDecoration: widget.backgroundDecoration,
                    pageController: widget.pageController,
                    onPageChanged: onPageChanged,
                    scrollDirection: widget.scrollDirection,
                  ),
                  Positioned(
                    right: 5,
                    child: PopupMenuButton<String>(
                      onSelected: (String result) {
                        if (result == "delete") {
                          deleteFile();
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text(context.lang.galleryDelete),
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
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final MemoryItem item = widget.galleryItems[index];
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
