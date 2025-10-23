// ignore_for_file: inference_failure_on_function_invocation

import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hashlib/random.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera/camera_preview_components/save_to_gallery.dart';
import 'package:twonly/src/views/camera/image_editor/action_button.dart';
import 'package:twonly/src/views/camera/image_editor/data/image_item.dart';
import 'package:twonly/src/views/camera/image_editor/data/layer.dart';
import 'package:twonly/src/views/camera/image_editor/layers_viewer.dart';
import 'package:twonly/src/views/camera/image_editor/modules/all_emojis.dart';
import 'package:twonly/src/views/camera/share_image_view.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';
import 'package:twonly/src/views/components/notification_badge.dart';
import 'package:video_player/video_player.dart';

List<Layer> layers = [];
List<Layer> undoLayers = [];
List<Layer> removedLayers = [];

class ShareImageEditorView extends StatefulWidget {
  const ShareImageEditorView({
    required this.sharedFromGallery,
    required this.mediaFileService,
    super.key,
    this.imageBytesFuture,
    this.sendToGroup,
  });
  final Future<Uint8List?>? imageBytesFuture;
  final Group? sendToGroup;
  final bool sharedFromGallery;
  final MediaFileService mediaFileService;
  @override
  State<ShareImageEditorView> createState() => _ShareImageEditorView();
}

class _ShareImageEditorView extends State<ShareImageEditorView> {
  double tabDownPosition = 0;
  bool sendingOrLoadingImage = true;
  bool loadingImage = true;
  bool isDisposed = false;
  HashSet<String> selectedGroupIds = HashSet();
  double widthRatio = 1;
  double heightRatio = 1;
  double pixelRatio = 1;
  VideoPlayerController? videoController;
  ImageItem currentImage = ImageItem();
  ScreenshotController screenshotController = ScreenshotController();

  MediaFileService get mediaService => widget.mediaFileService;
  MediaFile get media => widget.mediaFileService.mediaFile;

  @override
  void initState() {
    super.initState();

    layers.add(FilterLayerData());

    if (widget.sendToGroup != null) {
      selectedGroupIds.add(widget.sendToGroup!.groupId);
    }

    if (widget.imageBytesFuture != null) {
      unawaited(loadImage(widget.imageBytesFuture!));
    }

    if (media.type == MediaType.video) {
      setState(() {
        sendingOrLoadingImage = false;
        loadingImage = false;
      });
      videoController = VideoPlayerController.file(mediaService.originalPath);
      videoController?.setLooping(true);
      videoController?.initialize().then((_) async {
        await videoController!.play();
        setState(() {});
        // ignore: invalid_return_type_for_catch_error, argument_type_not_assignable_to_error_handler
      }).catchError(Log.error);
    }
  }

  @override
  void dispose() {
    isDisposed = true;
    layers.clear();
    videoController?.dispose();
    super.dispose();
  }

  void updateSelectedGroupIds(String groupId, bool checked) {
    if (checked) {
      if (media.requiresAuthentication) {
        selectedGroupIds.clear();
      }
      selectedGroupIds.add(groupId);
    } else {
      selectedGroupIds.remove(groupId);
    }
    setState(() {});
  }

  List<Widget> get actionsAtTheRight {
    if (layers.isNotEmpty &&
        layers.last.isEditing &&
        layers.last.hasCustomActionButtons) {
      return [];
    }
    return <Widget>[
      ActionButton(
        Icons.text_fields_rounded,
        tooltipText: context.lang.addTextItem,
        onPressed: () async {
          layers = layers.where((x) => !x.isDeleted).toList();
          if (layers.any((x) => x.isEditing)) return;
          undoLayers.clear();
          removedLayers.clear();
          layers.add(
            TextLayerData(
              textLayersBefore: layers.whereType<TextLayerData>().length,
            ),
          );
          setState(() {});
        },
      ),
      const SizedBox(height: 8),
      ActionButton(
        Icons.draw_rounded,
        tooltipText: context.lang.addDrawing,
        onPressed: () async {
          undoLayers.clear();
          removedLayers.clear();
          layers.add(DrawLayerData());
          setState(() {});
        },
      ),
      const SizedBox(height: 8),
      ActionButton(
        Icons.add_reaction_outlined,
        tooltipText: context.lang.addEmoji,
        onPressed: () async {
          final layer = await showModalBottomSheet(
            context: context,
            backgroundColor: Colors.black,
            builder: (BuildContext context) {
              return const Emojis();
            },
          ) as Layer?;
          if (layer == null) return;
          undoLayers.clear();
          removedLayers.clear();
          layers.add(layer);
          setState(() {});
        },
      ),
      const SizedBox(height: 8),
      NotificationBadge(
        count: (media.type != MediaType.video)
            ? '0'
            : media.displayLimitInMilliseconds == null
                ? '∞'
                : media.displayLimitInMilliseconds.toString(),
        child: ActionButton(
          (media.type != MediaType.video)
              ? media.displayLimitInMilliseconds == null
                  ? Icons.repeat_rounded
                  : Icons.repeat_one_rounded
              : Icons.timer_outlined,
          tooltipText: context.lang.protectAsARealTwonly,
          onPressed: () async {
            if (media.type != MediaType.video) {
              await mediaService.setDisplayLimit(
                  (media.displayLimitInMilliseconds == null) ? 0 : null);
              if (!mounted) return;
              setState(() {});
              return;
            }
            int? maxShowTime;
            if (media.displayLimitInMilliseconds == null) {
              maxShowTime = 1;
            } else if (media.displayLimitInMilliseconds == 1) {
              maxShowTime = 5;
            } else if (media.displayLimitInMilliseconds == 5) {
              maxShowTime = 20;
            }
            await mediaService.setDisplayLimit(maxShowTime);
            if (!mounted) return;
            setState(() {});
            await updateUserdata((user) {
              user.defaultShowTime = maxShowTime;
              return user;
            });
          },
        ),
      ),
      const SizedBox(height: 8),
      ActionButton(
        FontAwesomeIcons.shieldHeart,
        tooltipText: context.lang.protectAsARealTwonly,
        color: media.requiresAuthentication
            ? Theme.of(context).colorScheme.primary
            : Colors.white,
        onPressed: () async {
          await mediaService.setRequiresAuth(!media.requiresAuthentication);
          selectedGroupIds = HashSet();
          setState(() {});
        },
      ),
    ];
  }

  List<Widget> get actionsAtTheTop {
    if (layers.isNotEmpty &&
        layers.last.isEditing &&
        layers.last.hasCustomActionButtons) {
      return [];
    }
    return [
      ActionButton(
        FontAwesomeIcons.xmark,
        tooltipText: context.lang.close,
        onPressed: () async {
          Navigator.pop(context, false);
        },
      ),
      Expanded(child: Container()),
      const SizedBox(width: 8),
      ActionButton(
        FontAwesomeIcons.rotateLeft,
        tooltipText: context.lang.undo,
        disable: layers.where((x) => !x.isDeleted).length <= 2,
        onPressed: () {
          if (removedLayers.isNotEmpty) {
            final lastLayer = removedLayers.removeLast()
              ..isDeleted = false
              ..isEditing = false;
            layers.add(lastLayer);
            setState(() {});
            return;
          }
          layers = layers.where((x) => !x.isDeleted).toList();
          if (layers.length <= 2) {
            // do not remove image layer and filter layer
            return;
          }
          undoLayers.add(layers.removeLast());
          setState(() {});
        },
      ),
      const SizedBox(width: 8),
      ActionButton(
        FontAwesomeIcons.rotateRight,
        tooltipText: context.lang.redo,
        disable: undoLayers.isEmpty,
        onPressed: () {
          if (undoLayers.isEmpty) return;
          layers.add(undoLayers.removeLast());
          setState(() {});
        },
      ),
      const SizedBox(width: 70),
    ];
  }

  Future<void> pushShareImageView() async {
    final mediaStoreFuture =
        (media.type == MediaType.image) ? storeImageAsOriginal() : null;

    await videoController?.pause();
    if (isDisposed || !mounted) return;
    final wasSend = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareImageView(
          selectedGroupIds: selectedGroupIds,
          updateSelectedGroupIds: updateSelectedGroupIds,
          mediaStoreFuture: mediaStoreFuture,
          mediaFileService: mediaService,
        ),
      ),
    ) as bool?;
    if (wasSend != null && wasSend && mounted) {
      Navigator.pop(context, true);
    } else {
      await videoController?.play();
    }
  }

  Future<Uint8List?> getEditedImageBytes() async {
    if (layers.length == 1) {
      if (layers.first is BackgroundLayerData) {
        final image = (layers.first as BackgroundLayerData).image.bytes;
        return image;
      }
    }

    if (layers.length > 1 || media.type != MediaType.video) {
      for (final x in layers) {
        x.showCustomButtons = false;
      }
      setState(() {});
      final image = await screenshotController.capture(
        pixelRatio: pixelRatio,
      );
      if (image == null) {
        Log.error('screenshotController did not return image bytes');
        return null;
      }

      for (final x in layers) {
        x.showCustomButtons = true;
      }
      setState(() {});
      return image;
    }

    return null;
  }

  Future<bool> storeImageAsOriginal() async {
    final imageBytes = await getEditedImageBytes();
    if (imageBytes == null) return false;
    mediaService.originalPath.writeAsBytesSync(imageBytes);

    // In case the image was already stored, then rename the stored image.
    if (mediaService.storedPath.existsSync()) {
      final newPath = mediaService.storedPath.absolute.path
          .replaceFirst(media.mediaId, uuid.v7());
      mediaService.storedPath.renameSync(newPath);
    }
    return true;
  }

  Future<void> loadImage(Future<Uint8List?> imageBytesFuture) async {
    await currentImage.load(await imageBytesFuture);
    if (isDisposed) return;

    if (!context.mounted) return;

    layers.insert(
      0,
      BackgroundLayerData(
        image: currentImage,
      ),
    );
    setState(() {
      sendingOrLoadingImage = false;
      loadingImage = false;
    });
  }

  Future<void> sendImageToSinglePerson() async {
    if (sendingOrLoadingImage) return;
    setState(() {
      sendingOrLoadingImage = true;
    });

    if (media.type == MediaType.image) {
      await storeImageAsOriginal();
    }
    if (media.type == MediaType.video) {
      Log.error('TODO: COMBINE VIDEO AND IMAGE!!!');
    }

    if (!context.mounted) return;

    // Insert media file into the messages database and start uploading process in the background
    await insertMediaFileInMessagesTable(
      mediaService,
      [widget.sendToGroup!.groupId],
    );

    if (context.mounted) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return Scaffold(
      backgroundColor:
          widget.sharedFromGallery ? null : Colors.white.withAlpha(0),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTapDown: (details) {
              if (details.globalPosition.dy > 60) {
                tabDownPosition = details.globalPosition.dy - 60;
              } else {
                tabDownPosition = details.globalPosition.dy;
              }
            },
            onTap: () {
              if (layers.any((x) => x.isEditing)) {
                return;
              }
              layers = layers.where((x) => !x.isDeleted).toList();
              undoLayers.clear();
              removedLayers.clear();
              layers.add(
                TextLayerData(
                  offset: Offset(0, tabDownPosition),
                  textLayersBefore: layers.whereType<TextLayerData>().length,
                ),
              );
              setState(() {});
            },
            child: MediaViewSizing(
              bottomNavigation: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SaveToGalleryButton(
                      getMergedImage: getEditedImageBytes,
                      mediaService: mediaService,
                      displayButtonLabel: widget.sendToGroup == null,
                      isLoading: loadingImage,
                    ),
                    if (widget.sendToGroup != null) const SizedBox(width: 10),
                    if (widget.sendToGroup != null)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          iconColor: Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: pushShareImageView,
                        child: const FaIcon(FontAwesomeIcons.userPlus),
                      ),
                    SizedBox(width: widget.sendToGroup == null ? 20 : 10),
                    FilledButton.icon(
                      icon: sendingOrLoadingImage
                          ? SizedBox(
                              height: 12,
                              width: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                              ),
                            )
                          : const FaIcon(FontAwesomeIcons.solidPaperPlane),
                      onPressed: () async {
                        if (sendingOrLoadingImage) return;
                        if (widget.sendToGroup == null)
                          return pushShareImageView();
                        await sendImageToSinglePerson();
                      },
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all<EdgeInsets>(
                          const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 30,
                          ),
                        ),
                      ),
                      label: Text(
                        (widget.sendToGroup == null)
                            ? context.lang.shareImagedEditorShareWith
                            : widget.sendToGroup!.groupName,
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                  ],
                ),
              ),
              child: SizedBox(
                height: currentImage.height / pixelRatio,
                width: currentImage.width / pixelRatio,
                child: Stack(
                  children: [
                    if (videoController != null)
                      Positioned.fill(
                        child: VideoPlayer(videoController!),
                      ),
                    Screenshot(
                      controller: screenshotController,
                      child: LayersViewer(
                        layers: layers.where((x) => !x.isDeleted).toList(),
                        onUpdate: () {
                          for (final layer in layers) {
                            layer.isEditing = false;
                            if (layer.isDeleted) {
                              removedLayers.add(layer);
                            }
                          }
                          layers = layers.where((x) => !x.isDeleted).toList();
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 5,
            right: 0,
            child: SafeArea(
              child: Row(
                children: actionsAtTheTop,
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 100,
            child: Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: actionsAtTheRight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
