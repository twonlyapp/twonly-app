// ignore_for_file: inference_failure_on_function_invocation

import 'dart:async';
import 'dart:collection';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/screenshot.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera/camera_preview_components/main_camera_controller.dart';
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
    this.mainCameraController,
  });
  final ScreenshotImage? imageBytesFuture;
  final Group? sendToGroup;
  final bool sharedFromGallery;
  final MediaFileService mediaFileService;
  final MainCameraController? mainCameraController;
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
  Uint8List? imageBytes;
  VideoPlayerController? videoController;
  ImageItem currentImage = ImageItem();
  ScreenshotController screenshotController = ScreenshotController();

  MediaFileService get mediaService => widget.mediaFileService;
  MediaFile get media => widget.mediaFileService.mediaFile;

  @override
  void initState() {
    super.initState();

    if (media.type != MediaType.gif) {
      layers.add(FilterLayerData(key: GlobalKey()));
    }

    if (widget.sendToGroup != null) {
      selectedGroupIds.add(widget.sendToGroup!.groupId);
    }

    if (widget.mediaFileService.mediaFile.type == MediaType.image ||
        widget.mediaFileService.mediaFile.type == MediaType.gif) {
      if (widget.imageBytesFuture != null) {
        loadImage(widget.imageBytesFuture!);
      } else {
        if (widget.mediaFileService.tempPath.existsSync()) {
          loadImage(ScreenshotImage(file: widget.mediaFileService.tempPath));
        } else if (widget.mediaFileService.originalPath.existsSync()) {
          loadImage(
            ScreenshotImage(file: widget.mediaFileService.originalPath),
          );
        }
      }
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
    twonlyDB.mediaFilesDao.updateAllMediaFiles(
      const MediaFilesCompanion(
        isDraftMedia: Value(false),
      ),
    );
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

  Future<void> _setMaxShowTime(int? maxShowTime) async {
    await mediaService.setDisplayLimit(maxShowTime);
    if (!mounted) return;
    setState(() {});
    await updateUserdata((user) {
      user.defaultShowTime = maxShowTime;
      return user;
    });
  }

  Future<void> _setImageDisplayTime() async {
    if (media.type == MediaType.video) {
      await mediaService.setDisplayLimit(
        (media.displayLimitInMilliseconds == null) ? 0 : null,
      );
      if (!mounted) return;
      setState(() {});
      return;
    }

    final options = [
      1000,
      2000,
      3000,
      4000,
      5000,
      6000,
      7000,
      8000,
      9000,
      10000,
      15000,
      20000,
      null,
    ];

    var initialItem = options.length - 1;
    if (media.displayLimitInMilliseconds != null) {
      initialItem = options.indexOf(media.displayLimitInMilliseconds);
      if (initialItem == -1) {
        initialItem = options.length - 1;
      }
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 350,
        padding: const EdgeInsets.only(top: 6),
        margin:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32,
            scrollController: FixedExtentScrollController(
              initialItem: initialItem,
            ),
            onSelectedItemChanged: (int selectedItem) {
              _setMaxShowTime(options[selectedItem]);
            },
            children: options.map((e) {
              return Center(
                child: Text(e == null ? '∞' : '${e ~/ 1000}s'),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<Widget> get actionsAtTheRight {
    if (layers.isNotEmpty &&
        layers.last.isEditing &&
        layers.last.hasCustomActionButtons) {
      return [];
    }
    return <Widget>[
      if (media.type != MediaType.gif)
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
                key: GlobalKey(),
                textLayersBefore: layers.whereType<TextLayerData>().length,
              ),
            );
            setState(() {});
          },
        ),
      const SizedBox(height: 8),
      if (media.type != MediaType.gif)
        ActionButton(
          Icons.draw_rounded,
          tooltipText: context.lang.addDrawing,
          onPressed: () async {
            undoLayers.clear();
            removedLayers.clear();
            layers.add(DrawLayerData(key: GlobalKey()));
            setState(() {});
          },
        ),
      const SizedBox(height: 8),
      if (media.type != MediaType.gif)
        ActionButton(
          Icons.add_reaction_outlined,
          tooltipText: context.lang.addEmoji,
          onPressed: () async {
            final layer = await showModalBottomSheet(
              context: context,
              backgroundColor: Colors.black,
              builder: (BuildContext context) {
                return const EmojiPickerBottom();
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
        count: (media.type == MediaType.video)
            ? '0'
            : media.displayLimitInMilliseconds == null
                ? '∞'
                : (media.displayLimitInMilliseconds! ~/ 1000).toString(),
        child: ActionButton(
          (media.type == MediaType.video)
              ? media.displayLimitInMilliseconds == null
                  ? Icons.repeat_rounded
                  : Icons.repeat_one_rounded
              : Icons.timer_outlined,
          tooltipText: context.lang.protectAsARealTwonly,
          onPressed: _setImageDisplayTime,
        ),
      ),
      if (media.type == MediaType.video)
        ActionButton(
          (mediaService.removeAudio)
              ? Icons.volume_off_rounded
              : Icons.volume_up_rounded,
          tooltipText: 'Enable Audio in Video',
          color: (mediaService.removeAudio)
              ? Colors.white.withAlpha(160)
              : Colors.white,
          onPressed: () async {
            await mediaService.toggleRemoveAudio();
            if (mediaService.removeAudio) {
              await videoController?.setVolume(0);
            } else {
              await videoController?.setVolume(100);
            }
            if (mounted) setState(() {});
          },
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

  Future<bool?> _showBackDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            context.lang.dialogAskDeleteMediaFilePopTitle,
          ),
          actions: [
            FilledButton(
              child: Text(context.lang.dialogAskDeleteMediaFilePopDelete),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
            TextButton(
              child: Text(context.lang.cancel),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> askToCloseThenClose() async {
    final shouldPop = await _showBackDialog() ?? false;
    if (mounted && shouldPop) {
      Navigator.pop(context);
    }
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
          final nonImageFilterLayer = layers.where(
            (x) => x is! BackgroundLayerData && x is! FilterLayerData,
          );
          if (nonImageFilterLayer.isEmpty) {
            Navigator.pop(context, false);
          } else {
            await askToCloseThenClose();
          }
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
    final mediaStoreFuture = storeImageAsOriginal();

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

  Future<ScreenshotImage?> getEditedImageBytes() async {
    if (layers.length == 1) {
      if (layers.first is BackgroundLayerData) {
        final image = (layers.first as BackgroundLayerData).image.bytes;
        return ScreenshotImage(imageBytes: image);
      }
    }

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
    if (mounted) {
      setState(() {});
    }
    return image;
  }

  Future<Uint8List?> storeImageAsOriginal() async {
    if (mediaService.overlayImagePath.existsSync()) {
      mediaService.overlayImagePath.deleteSync();
    }
    if (mediaService.tempPath.existsSync()) {
      mediaService.tempPath.deleteSync();
    }
    if (mediaService.originalPath.existsSync()) {
      mediaService.originalPath.deleteSync();
    }
    var bytes = imageBytes;
    if (media.type == MediaType.gif) {
      mediaService.originalPath.writeAsBytesSync(imageBytes!.toList());
    } else {
      final image = await getEditedImageBytes();
      if (image == null) return null;
      bytes = await image.getBytes();
      if (bytes == null) {
        Log.error('imageBytes are empty');
        return null;
      }
      if (media.type == MediaType.image || media.type == MediaType.gif) {
        mediaService.originalPath.writeAsBytesSync(bytes);
      } else if (media.type == MediaType.video) {
        mediaService.overlayImagePath.writeAsBytesSync(bytes);
      } else {
        Log.error('MediaType not supported: ${media.type}');
      }
    }

    // In case the image was already stored, then rename the stored image.
    if (mediaService.storedPath.existsSync()) {
      final mediaFile = await twonlyDB.mediaFilesDao.insertMedia(
        MediaFilesCompanion(
          type: Value(mediaService.mediaFile.type),
          createdAt: Value(DateTime.now()),
          stored: const Value(true),
        ),
      );
      if (mediaFile != null) {
        mediaService.storedPath
            .renameSync(MediaFileService(mediaFile).storedPath.path);
      }
    }
    return bytes;
  }

  Future<void> loadImage(ScreenshotImage imageBytesFuture) async {
    imageBytes = await imageBytesFuture.getBytes();
    // store this image so it can be used as a draft in case the app is restarted
    mediaService.originalPath.writeAsBytesSync(imageBytes!.toList());

    await currentImage.load(imageBytes);
    if (isDisposed) return;

    if (!context.mounted) return;

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (context.mounted) {
        await widget.mainCameraController?.closeCamera();
      }
    });

    layers.insert(
      0,
      BackgroundLayerData(
        key: GlobalKey(),
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

    if (!context.mounted) return;

    // Insert media file into the messages database and start uploading process in the background
    unawaited(
      insertMediaFileInMessagesTable(
        mediaService,
        [widget.sendToGroup!.groupId],
        storeImageAsOriginal(),
      ),
    );

    if (context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return PopScope<bool?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, bool? result) async {
        if (didPop) return;
        await askToCloseThenClose();
      },
      child: Scaffold(
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
                    key: GlobalKey(),
                    offset: Offset(0, tabDownPosition),
                    textLayersBefore: layers.whereType<TextLayerData>().length,
                  ),
                );
                setState(() {});
              },
              child: MediaViewSizing(
                requiredHeight: 59,
                bottomNavigation: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SaveToGalleryButton(
                        storeImageAsOriginal: storeImageAsOriginal,
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
                          if (widget.sendToGroup == null) {
                            return pushShareImageView();
                          }
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
                              : substringBy(widget.sendToGroup!.groupName, 15),
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
      ),
    );
  }
}
