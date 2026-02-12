import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/camera_preview_components/save_to_gallery.dart';
import 'package:twonly/src/views/camera/share_image_editor.view.dart';
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
    final confirmed = await showAlertDialog(
      context,
      context.lang.deleteImageTitle,
      context.lang.deleteImageBody,
    );

    if (!confirmed) return;

    widget.galleryItems[currentIndex].mediaService.fullMediaRemoval();
    await twonlyDB.mediaFilesDao.deleteMediaFile(
      widget.galleryItems[currentIndex].mediaService.mediaFile.mediaId,
    );

    widget.galleryItems.removeAt(currentIndex);
    setState(() {});
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> exportFile() async {
    final item = widget.galleryItems[currentIndex].mediaService;

    try {
      if (item.mediaFile.type == MediaType.video) {
        await saveVideoToGallery(item.storedPath.path);
      } else if (item.mediaFile.type == MediaType.image ||
          item.mediaFile.type == MediaType.gif) {
        final imageBytes = await item.storedPath.readAsBytes();
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

  Future<void> shareMediaFile() async {
    final orgMediaService = widget.galleryItems[currentIndex].mediaService;

    final newMediaService = await initializeMediaUpload(
      orgMediaService.mediaFile.type,
      gUser.defaultShowTime,
    );
    if (newMediaService == null) {
      Log.error('Could not create new mediaFIle');
      return;
    }

    if (orgMediaService.storedPath.existsSync()) {
      orgMediaService.storedPath.copySync(newMediaService.originalPath.path);
    } else if (orgMediaService.tempPath.existsSync()) {
      orgMediaService.tempPath.copySync(newMediaService.originalPath.path);
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareImageEditorView(
          mediaFileService: newMediaService,
          sharedFromGallery: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgMediaService = widget.galleryItems[currentIndex].mediaService;
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
                bottomNavigation: ColoredBox(
                  color: context.color.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!orgMediaService.storedPath.existsSync())
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SaveToGalleryButton(
                            isLoading: false,
                            displayButtonLabel: true,
                            mediaService: orgMediaService,
                          ),
                        ),
                      FilledButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.solidPaperPlane),
                        onPressed: shareMediaFile,
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all<EdgeInsets>(
                            const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 30,
                            ),
                          ),
                          backgroundColor: WidgetStateProperty.all<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
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
                        onSelected: (result) async {
                          if (result == 'delete') {
                            await deleteFile();
                          }
                          if (result == 'export') {
                            await exportFile();
                          }
                        },
                        itemBuilder: (context) => <PopupMenuEntry<String>>[
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
                    ),
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

    var filePath = item.mediaService.storedPath;
    if (!filePath.existsSync()) {
      filePath = item.mediaService.tempPath;
    }

    return item.mediaService.mediaFile.type == MediaType.video
        ? PhotoViewGalleryPageOptions.customChild(
            child: VideoPlayerWrapper(
              videoPath: filePath,
            ),
            // childSize: const Size(300, 300),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4.1,
            heroAttributes: PhotoViewHeroAttributes(
              tag: item.mediaService.mediaFile.mediaId,
            ),
          )
        : PhotoViewGalleryPageOptions(
            imageProvider: FileImage(filePath),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4.1,
            heroAttributes: PhotoViewHeroAttributes(
              tag: item.mediaService.mediaFile.mediaId,
            ),
          );
  }
}
