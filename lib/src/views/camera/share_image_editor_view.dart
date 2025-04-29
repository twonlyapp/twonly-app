import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:logging/logging.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/providers/api/media_send.dart';
import 'package:twonly/src/views/camera/components/save_to_gallery.dart';
import 'package:twonly/src/views/camera/image_editor/action_button.dart';
import 'package:twonly/src/views/components/media_view_sizing.dart';
import 'package:twonly/src/views/components/notification_badge.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera/share_image_view.dart';
import 'package:flutter/services.dart';
import 'package:twonly/src/views/camera/image_editor/data/image_item.dart';
import 'package:twonly/src/views/camera/image_editor/data/layer.dart';
import 'package:twonly/src/views/camera/image_editor/layers_viewer.dart';
import 'package:twonly/src/views/camera/image_editor/modules/all_emojis.dart';
import 'package:screenshot/screenshot.dart';
import 'package:video_player/video_player.dart';

List<Layer> layers = [];
List<Layer> undoLayers = [];
List<Layer> removedLayers = [];

const gMediaShowInfinite = 999999;

class ShareImageEditorView extends StatefulWidget {
  const ShareImageEditorView({
    super.key,
    this.imageBytes,
    this.sendTo,
    this.videoFilePath,
    required this.mirrorVideo,
  });
  final Future<Uint8List?>? imageBytes;
  final XFile? videoFilePath;
  final Contact? sendTo;
  final bool mirrorVideo;
  @override
  State<ShareImageEditorView> createState() => _ShareImageEditorView();
}

class _ShareImageEditorView extends State<ShareImageEditorView> {
  bool _isRealTwonly = false;
  bool videoWithAudio = true;
  int maxShowTime = gMediaShowInfinite;
  String? sendNextMediaToUserName;
  double tabDownPostion = 0;
  bool sendingOrLoadingImage = true;
  bool isDisposed = false;
  double widthRatio = 1, heightRatio = 1, pixelRatio = 1;
  VideoPlayerController? videoController;

  ImageItem currentImage = ImageItem();
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    initAsync();
    if (widget.imageBytes != null) {
      loadImage(widget.imageBytes!);
    } else if (widget.videoFilePath != null) {
      layers.add(FilterLayerData());
      setState(() {
        sendingOrLoadingImage = false;
      });
      videoController =
          VideoPlayerController.file(File(widget.videoFilePath!.path));
      videoController?.setLooping(true);
      videoController?.initialize().then((_) {
        videoController!.play();
        setState(() {});
      }).catchError((Object error) {
        Logger("ui.share_image_editor").shout(error);
      });
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

  @override
  void dispose() {
    isDisposed = true;
    layers.clear();
    videoController?.dispose();
    super.dispose();
  }

  Future updateAsync(int userId) async {
    if (sendNextMediaToUserName != null) return;
    Contact? contact = await twonlyDatabase.contactsDao
        .getContactByUserId(userId)
        .getSingleOrNull();
    if (contact != null) {
      sendNextMediaToUserName = getContactDisplayName(contact);
    }
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
          EmojiLayerData? layer = await showModalBottomSheet(
            context: context,
            backgroundColor: Colors.black,
            builder: (BuildContext context) {
              return const Emojis();
            },
          );
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
            ? "0"
            : maxShowTime == 999999
                ? "∞"
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
              maxShowTime = 4;
            } else if (maxShowTime >= 22) {
              maxShowTime = gMediaShowInfinite;
            } else {
              maxShowTime = maxShowTime + 8;
            }
            setState(() {});
            var user = await getUser();
            if (user != null) {
              user.defaultShowTime = maxShowTime;
              updateUser(user);
            }
          },
        ),
      ),
      // https://github.com/jonataslaw/VideoCompress/issues/184
      // if (widget.videoFilePath != null) const SizedBox(height: 8),
      // if (widget.videoFilePath != null)
      //   ActionButton(
      //     (videoWithAudio) ? Icons.volume_up_rounded : Icons.volume_off_rounded,
      //     tooltipText: context.lang.protectAsARealTwonly,
      //     color: Colors.white,
      //     onPressed: () async {
      //       setState(() {
      //         videoWithAudio = !videoWithAudio;
      //       });
      //     },
      //   ),
      const SizedBox(height: 8),
      ActionButton(
        FontAwesomeIcons.shieldHeart,
        tooltipText: context.lang.protectAsARealTwonly,
        color: _isRealTwonly
            ? Theme.of(context).colorScheme.primary
            : Colors.white,
        onPressed: () async {
          _isRealTwonly = !_isRealTwonly;
          if (_isRealTwonly) {
            maxShowTime = 12;
          }
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
        disable: layers.where((x) => x.isDeleted).length <= 2 &&
            removedLayers.isEmpty,
        onPressed: () {
          if (removedLayers.isNotEmpty) {
            layers.add(removedLayers.removeLast());
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

  Future pushShareImageView() async {
    Future<Uint8List?> imageBytes = getMergedImage();
    bool? wasSend = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareImageView(
          imageBytesFuture: imageBytes,
          isRealTwonly: _isRealTwonly,
          maxShowTime: maxShowTime,
          preselectedUser: widget.sendTo,
          videoFilePath: widget.videoFilePath,
          mirrorVideo: widget.mirrorVideo,
        ),
      ),
    );
    if (wasSend != null && wasSend && context.mounted) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
    }
  }

  Future<Uint8List?> getMergedImage() async {
    Uint8List? image;

    if (layers.length > 1 || widget.videoFilePath != null) {
      for (var x in layers) {
        x.showCustomButtons = false;
      }
      setState(() {});
      image = await screenshotController.capture(pixelRatio: pixelRatio);
      for (var x in layers) {
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
    Uint8List? imageBytes = await imageFile;
    await currentImage.load(imageBytes);
    if (isDisposed) return;

    if (!context.mounted) return;

    layers.clear();

    layers.add(BackgroundLayerData(
      image: currentImage,
    ));

    layers.add(FilterLayerData());
    setState(() {
      sendingOrLoadingImage = false;
    });
  }

  Future sendImageToSinglePerson() async {
    if (sendingOrLoadingImage) return;
    setState(() {
      sendingOrLoadingImage = true;
    });
    Uint8List? imageBytes = await getMergedImage();
    if (!context.mounted) return;
    if (imageBytes == null) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
      return;
    }
    sendMediaFile(
      [widget.sendTo!.userId],
      imageBytes,
      _isRealTwonly,
      maxShowTime,
      widget.videoFilePath,
      videoWithAudio,
      widget.mirrorVideo,
    );
    if (context.mounted) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    pixelRatio = MediaQuery.of(context).devicePixelRatio;

    if (widget.sendTo != null) {
      sendNextMediaToUserName = getContactDisplayName(widget.sendTo!);
    }

    return Scaffold(
      backgroundColor: Colors.white.withAlpha(0),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTapDown: (details) {
              if (details.globalPosition.dy > 60) {
                tabDownPostion = details.globalPosition.dy - 60;
              } else {
                tabDownPostion = details.globalPosition.dy;
              }
            },
            onTap: () {
              if (layers.any((x) => x.isEditing)) {
                return;
              }
              undoLayers.clear();
              removedLayers.clear();
              layers.add(TextLayerData(
                offset: Offset(0, tabDownPostion),
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
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SaveToGalleryButton(
                  getMergedImage: getMergedImage,
                  sendNextMediaToUserName: sendNextMediaToUserName,
                ),
                if (sendNextMediaToUserName != null) SizedBox(width: 10),
                if (sendNextMediaToUserName != null)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      iconColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: pushShareImageView,
                    child: FaIcon(FontAwesomeIcons.userPlus),
                  ),
                SizedBox(width: sendNextMediaToUserName == null ? 20 : 10),
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
                      : FaIcon(FontAwesomeIcons.solidPaperPlane),
                  onPressed: () async {
                    if (sendingOrLoadingImage) return;
                    if (widget.sendTo == null) return pushShareImageView();
                    sendImageToSinglePerson();
                  },
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all<EdgeInsets>(
                      EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    ),
                  ),
                  label: Text(
                    (sendNextMediaToUserName == null)
                        ? context.lang.shareImagedEditorShareWith
                        : sendNextMediaToUserName!,
                    style: TextStyle(fontSize: 17),
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
