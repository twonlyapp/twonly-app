// ignore_for_file: inference_failure_on_function_invocation

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/services/api/media_upload.dart';
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
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';
import 'package:twonly/src/views/components/notification_badge.dart';
import 'package:twonly/src/views/settings/subscription/subscription.view.dart';
import 'package:video_player/video_player.dart';

List<Layer> layers = [];
List<Layer> undoLayers = [];
List<Layer> removedLayers = [];

const gMediaShowInfinite = 999999;

class ShareImageEditorView extends StatefulWidget {
  const ShareImageEditorView({
    required this.mirrorVideo,
    required this.useHighQuality,
    required this.sharedFromGallery,
    super.key,
    this.imageBytes,
    this.sendTo,
    this.videoFilePath,
  });
  final Future<Uint8List?>? imageBytes;
  final File? videoFilePath;
  final Contact? sendTo;
  final bool mirrorVideo;
  final bool useHighQuality;
  final bool sharedFromGallery;
  @override
  State<ShareImageEditorView> createState() => _ShareImageEditorView();
}

class _ShareImageEditorView extends State<ShareImageEditorView> {
  bool _isRealTwonly = false;
  int maxShowTime = gMediaShowInfinite;
  double tabDownPosition = 0;
  bool sendingOrLoadingImage = true;
  bool loadingImage = true;
  bool isDisposed = false;
  HashSet<int> selectedUserIds = HashSet();
  double widthRatio = 1, heightRatio = 1, pixelRatio = 1;
  VideoPlayerController? videoController;
  ImageItem currentImage = ImageItem();
  ScreenshotController screenshotController = ScreenshotController();

  /// Media upload variables
  int? mediaUploadId;
  Future<bool>? videoUploadHandler;

  @override
  void initState() {
    super.initState();
    initAsync();
    initMediaFileUpload();
    layers.add(FilterLayerData());
    if (widget.imageBytes != null) {
      loadImage(widget.imageBytes!);
    } else if (widget.videoFilePath != null) {
      setState(() {
        sendingOrLoadingImage = false;
        loadingImage = false;
      });
      videoController = VideoPlayerController.file(widget.videoFilePath!);
      videoController?.setLooping(true);
      videoController?.initialize().then((_) {
        videoController!.play();
        setState(() {});
        // ignore: invalid_return_type_for_catch_error, argument_type_not_assignable_to_error_handler
      }).catchError(Log.error);
    }
  }

  void initAsync() async {
    final user = await getUser();
    if (user == null) return;
    if (user.defaultShowTime != null) {
      setState(() {
        maxShowTime = user.defaultShowTime!;
      });
    }
  }

  Future<void> initMediaFileUpload() async {
    // media init was already called...
    if (mediaUploadId != null) return;

    mediaUploadId = await initMediaUpload();

    if (widget.videoFilePath != null && mediaUploadId != null) {
      // start with the video compression...
      videoUploadHandler =
          addVideoToUpload(mediaUploadId!, widget.videoFilePath!);
    }
  }

  @override
  void dispose() {
    isDisposed = true;
    layers.clear();
    videoController?.dispose();
    super.dispose();
  }

  void updateStatus(int userId, bool checked) {
    if (checked) {
      if (_isRealTwonly) {
        selectedUserIds.clear();
      }
      selectedUserIds.add(userId);
    } else {
      selectedUserIds.remove(userId);
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
          layers.add(TextLayerData(
            textLayersBefore: layers.whereType<TextLayerData>().length,
          ));
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
        count: (widget.videoFilePath != null)
            ? '0'
            : maxShowTime == 999999
                ? '∞'
                : maxShowTime.toString(),
        child: ActionButton(
          (widget.videoFilePath != null)
              ? maxShowTime == 999999
                  ? Icons.repeat_rounded
                  : Icons.repeat_one_rounded
              : Icons.timer_outlined,
          tooltipText: context.lang.protectAsARealTwonly,
          onPressed: () async {
            if (widget.videoFilePath != null) {
              setState(() {
                if (maxShowTime == gMediaShowInfinite) {
                  maxShowTime = 0;
                } else {
                  maxShowTime = gMediaShowInfinite;
                }
              });
              return;
            }
            if (maxShowTime == gMediaShowInfinite) {
              maxShowTime = 1;
            } else if (maxShowTime == 1) {
              maxShowTime = 5;
            } else if (maxShowTime == 5) {
              maxShowTime = 20;
            } else {
              maxShowTime = gMediaShowInfinite;
            }
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
        color: _isRealTwonly
            ? Theme.of(context).colorScheme.primary
            : Colors.white,
        onPressed: () async {
          if (widget.sendTo != null) {
            if (!widget.sendTo!.verified) {
              await showAlertDialog(
                context,
                context.lang.shareImageUserNotVerified,
                context.lang.shareImageUserNotVerifiedDesc,
              );
              return;
            }
          }
          _isRealTwonly = !_isRealTwonly;
          if (_isRealTwonly) {
            maxShowTime = 12;
          }
          selectedUserIds = HashSet();
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
      const SizedBox(width: 70)
    ];
  }

  Future<void> pushShareImageView() async {
    if (mediaUploadId == null) {
      await initMediaFileUpload();
      if (mediaUploadId == null) return;
    }
    final imageBytes = getMergedImage();
    await videoController?.pause();
    if (isDisposed || !mounted) return;
    final wasSend = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareImageView(
          imageBytesFuture: imageBytes,
          isRealTwonly: _isRealTwonly,
          maxShowTime: maxShowTime,
          selectedUserIds: selectedUserIds,
          updateStatus: updateStatus,
          videoUploadHandler: videoUploadHandler,
          mediaUploadId: mediaUploadId!,
          mirrorVideo: widget.mirrorVideo,
        ),
      ),
    ) as bool?;
    if (wasSend != null && wasSend && mounted) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
    } else {
      await videoController?.play();
    }
  }

  Future<Uint8List?> getMergedImage() async {
    Uint8List? image;

    if (layers.length > 1 || widget.videoFilePath != null) {
      for (final x in layers) {
        x.showCustomButtons = false;
      }
      setState(() {});
      image = await screenshotController.capture(
          pixelRatio: (widget.useHighQuality) ? pixelRatio : 1);
      for (final x in layers) {
        x.showCustomButtons = true;
      }
      setState(() {});
    } else if (layers.length == 1) {
      if (layers.first is BackgroundLayerData) {
        image = (layers.first as BackgroundLayerData).image.bytes;
      }
    }
    return image;
  }

  Future<void> loadImage(Future<Uint8List?> imageFile) async {
    final imageBytes = await imageFile;
    await currentImage.load(imageBytes);
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
    final imageBytes = await getMergedImage();
    if (!context.mounted) return;
    if (imageBytes == null) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
      return;
    }
    final err = await isAllowedToSend();
    if (!context.mounted) return;

    if (err != null) {
      setState(() {
        sendingOrLoadingImage = false;
      });
      if (mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (context) {
          return SubscriptionView(
            redirectError: err,
          );
        }));
      }
    } else {
      final imageHandler = addOrModifyImageToUpload(mediaUploadId!, imageBytes);

      // first finalize the upload
      await finalizeUpload(
        mediaUploadId!,
        [widget.sendTo!.userId],
        _isRealTwonly,
        widget.videoFilePath != null,
        widget.mirrorVideo,
        maxShowTime,
      );

      /// then call the upload process in the background
      await encryptMediaFiles(
        mediaUploadId!,
        imageHandler,
        videoUploadHandler,
      );

      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context, true);
      }
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
              layers.add(TextLayerData(
                offset: Offset(0, tabDownPosition),
                textLayersBefore: layers.whereType<TextLayerData>().length,
              ));
              setState(() {});
            },
            child: MediaViewSizing(
              child: SizedBox(
                height: currentImage.height / pixelRatio,
                width: currentImage.width / pixelRatio,
                child: Stack(
                  children: [
                    if (videoController != null)
                      Positioned.fill(
                        child: Transform.flip(
                          flipX: widget.mirrorVideo,
                          child: VideoPlayer(videoController!),
                        ),
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
      bottomNavigationBar: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SaveToGalleryButton(
                  getMergedImage: getMergedImage,
                  mediaUploadId: mediaUploadId,
                  videoFilePath: widget.videoFilePath,
                  displayButtonLabel: widget.sendTo == null,
                  isLoading: loadingImage,
                ),
                if (widget.sendTo != null) const SizedBox(width: 10),
                if (widget.sendTo != null)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      iconColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: pushShareImageView,
                    child: const FaIcon(FontAwesomeIcons.userPlus),
                  ),
                SizedBox(width: widget.sendTo == null ? 20 : 10),
                FilledButton.icon(
                  icon: sendingOrLoadingImage
                      ? SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        )
                      : const FaIcon(FontAwesomeIcons.solidPaperPlane),
                  onPressed: () async {
                    if (sendingOrLoadingImage) return;
                    if (widget.sendTo == null) return pushShareImageView();
                    await sendImageToSinglePerson();
                  },
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    ),
                  ),
                  label: Text(
                    (widget.sendTo == null)
                        ? context.lang.shareImagedEditorShareWith
                        : getContactDisplayName(widget.sendTo!),
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
