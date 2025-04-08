import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/components/image_editor/action_button.dart';
import 'package:twonly/src/components/media_view_sizing.dart';
import 'package:twonly/src/components/notification_badge.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/providers/api/media.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera_to_share/share_image_view.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:twonly/src/components/image_editor/data/image_item.dart';
import 'package:twonly/src/components/image_editor/data/layer.dart';
import 'package:twonly/src/components/image_editor/layers_viewer.dart';
import 'package:twonly/src/components/image_editor/modules/all_emojis.dart';
import 'package:screenshot/screenshot.dart';
import 'package:twonly/src/views/home_view.dart';

List<Layer> layers = [];
List<Layer> undoLayers = [];
List<Layer> removedLayers = [];

class ShareImageEditorView extends StatefulWidget {
  const ShareImageEditorView({super.key, required this.imageBytes});
  final Future<Uint8List?> imageBytes;
  @override
  State<ShareImageEditorView> createState() => _ShareImageEditorView();
}

class _ShareImageEditorView extends State<ShareImageEditorView> {
  bool _imageSaved = false;
  bool _imageSaving = false;
  bool _isRealTwonly = false;
  int maxShowTime = 999999;
  String? sendNextMediaToUserName;
  double tabDownPostion = 0;
  bool sendingImage = false;

  ImageItem currentImage = ImageItem();
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    initAsync();
    loadImage(widget.imageBytes);
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
    layers.clear();
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
        FontAwesomeIcons.font,
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
        FontAwesomeIcons.pencil,
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
        FontAwesomeIcons.faceGrinWide,
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
        count: maxShowTime == 999999 ? "∞" : maxShowTime.toString(),
        // count: "",
        child: ActionButton(
          FontAwesomeIcons.stopwatch,
          tooltipText: context.lang.protectAsARealTwonly,
          onPressed: () async {
            if (maxShowTime == 999999) {
              maxShowTime = 4;
            } else if (maxShowTime >= 22) {
              maxShowTime = 999999;
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
          Navigator.pop(context);
        },
      ),
      Expanded(child: Container()),
      const SizedBox(width: 8),
      ActionButton(
        FontAwesomeIcons.rotateLeft,
        tooltipText: context.lang.undo,
        disable: layers.length <= 2 && removedLayers.isEmpty,
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

  double widthRatio = 1, heightRatio = 1, pixelRatio = 1;

  Future<Uint8List?> getMergedImage() async {
    Uint8List? image;

    if (layers.length > 1) {
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

    layers.clear();

    layers.add(BackgroundLayerData(
      image: currentImage,
    ));

    layers.add(FilterLayerData());

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    pixelRatio = MediaQuery.of(context).devicePixelRatio;

    if (globalSendNextMediaToUser != null) {
      sendNextMediaToUserName =
          getContactDisplayName(globalSendNextMediaToUser!);
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
              SizedBox(
                height: currentImage.height / pixelRatio,
                width: currentImage.width / pixelRatio,
                child: Screenshot(
                  controller: screenshotController,
                  child: LayersViewer(
                    layers: layers.where((x) => !x.isDeleted).toList(),
                    onUpdate: () {
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 5,
            left: 0,
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
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    iconColor: _imageSaved
                        ? Theme.of(context).colorScheme.outline
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: _imageSaved
                        ? Theme.of(context).colorScheme.outline
                        : Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () async {
                    setState(() {
                      _imageSaving = true;
                    });
                    Uint8List? imageBytes = await getMergedImage();
                    if (imageBytes == null || !context.mounted) return;
                    final res = await saveImageToGallery(imageBytes);
                    if (res == null) {
                      setState(() {
                        _imageSaving = false;
                        _imageSaved = true;
                      });
                    }
                  },
                  child: Row(
                    children: [
                      _imageSaving
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1))
                          : _imageSaved
                              ? Icon(Icons.check)
                              : FaIcon(FontAwesomeIcons.floppyDisk),
                      if (sendNextMediaToUserName == null) SizedBox(width: 10),
                      if (sendNextMediaToUserName == null)
                        Text(_imageSaved
                            ? context.lang.shareImagedEditorSavedImage
                            : context.lang.shareImagedEditorSaveImage)
                    ],
                  ),
                ),
                if (sendNextMediaToUserName != null) SizedBox(width: 10),
                if (sendNextMediaToUserName != null)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      iconColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () async {
                      Future<Uint8List?> imageBytes = getMergedImage();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShareImageView(
                            imageBytesFuture: imageBytes,
                            isRealTwonly: _isRealTwonly,
                            maxShowTime: maxShowTime,
                          ),
                        ),
                      );
                    },
                    child: FaIcon(FontAwesomeIcons.userPlus),
                  ),
                if (sendNextMediaToUserName != null) SizedBox(width: 10),
                if (sendNextMediaToUserName == null) SizedBox(width: 20),
                FilledButton.icon(
                  icon: sendingImage
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
                    if (sendingImage) return;
                    if (globalSendNextMediaToUser != null) {
                      setState(() {
                        sendingImage = true;
                      });
                      Uint8List? imageBytes = await getMergedImage();
                      if (!context.mounted) return;
                      if (imageBytes == null) {
                        Navigator.pop(context);
                        return;
                      }
                      sendImage(
                        [globalSendNextMediaToUser!.userId],
                        imageBytes,
                        _isRealTwonly,
                        maxShowTime,
                      );
                      Navigator.popUntil(context, (route) => route.isFirst);
                      globalUpdateOfHomeViewPageIndex(1);
                      return;
                    }
                    Future<Uint8List?> imageBytes = getMergedImage();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShareImageView(
                          imageBytesFuture: imageBytes,
                          isRealTwonly: _isRealTwonly,
                          maxShowTime: maxShowTime,
                        ),
                      ),
                    );
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
