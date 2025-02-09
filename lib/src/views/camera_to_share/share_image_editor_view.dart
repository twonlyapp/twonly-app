import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/components/image_editor/action_button.dart';
import 'package:twonly/src/components/media_view_sizing.dart';
import 'package:twonly/src/components/notification_badge.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera_to_share/share_image_view.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:twonly/src/components/image_editor/data/image_item.dart';
import 'package:twonly/src/components/image_editor/data/layer.dart';
import 'package:twonly/src/components/image_editor/layers_viewer.dart';
import 'package:twonly/src/components/image_editor/modules/all_emojis.dart';
import 'package:screenshot/screenshot.dart';

List<Layer> layers = [];
List<Layer> undoLayers = [];
List<Layer> removedLayers = [];

class ShareImageEditorView extends StatefulWidget {
  const ShareImageEditorView({super.key, required this.imageBytes});
  final Uint8List imageBytes;
  @override
  State<ShareImageEditorView> createState() => _ShareImageEditorView();
}

class _ShareImageEditorView extends State<ShareImageEditorView> {
  bool _imageSaved = false;
  bool _imageSaving = false;
  bool _isRealTwonly = false;
  int _maxShowTime = 18;

  ImageItem currentImage = ImageItem();
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    loadImage(widget.imageBytes);
  }

  @override
  void dispose() {
    layers.clear();
    super.dispose();
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
          undoLayers.clear();
          removedLayers.clear();
          layers.add(TextLayerData());
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
        count: _maxShowTime == 999999 ? "∞" : _maxShowTime.toString(),
        // count: "",
        child: ActionButton(
          FontAwesomeIcons.stopwatch,
          tooltipText: context.lang.protectAsARealTwonly,
          // disable: _isRealTwonly,
          onPressed: () async {
            if (_maxShowTime == 999999) {
              _maxShowTime = 4;
            } else if (_maxShowTime >= 22) {
              _maxShowTime = 999999;
            } else {
              _maxShowTime = _maxShowTime + 4;
            }
            setState(() {});

            // _maxShowTime =
            // _isRealTwonly = !_isRealTwonly;
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
            _maxShowTime = 12;
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
        disable: layers.length <= 1 && removedLayers.isEmpty,
        onPressed: () {
          if (removedLayers.isNotEmpty) {
            layers.add(removedLayers.removeLast());
            setState(() {});
            return;
          }
          layers = layers.where((x) => !x.isDeleted).toList();
          if (layers.length <= 1) return; // do not remove image layer
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
      image = await screenshotController.capture(pixelRatio: pixelRatio);
      for (var x in layers) {
        x.showCustomButtons = true;
      }
    } else if (layers.length == 1) {
      if (layers.first is BackgroundLayerData) {
        image = (layers.first as BackgroundLayerData).image.bytes;
      }
    }
    return image;
  }

  Future<void> loadImage(dynamic imageFile) async {
    await currentImage.load(imageFile);

    layers.clear();

    layers.add(BackgroundLayerData(
      image: currentImage,
    ));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return Scaffold(
      backgroundColor: Colors.white.withAlpha(0),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () {
              if (layers.any((x) => x.isEditing)) {
                return;
              }
              undoLayers.clear();
              removedLayers.clear();
              layers.add(TextLayerData());
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
                OutlinedButton.icon(
                  icon: _imageSaving
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1))
                      : _imageSaved
                          ? Icon(Icons.check)
                          : FaIcon(FontAwesomeIcons.floppyDisk),
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
                  label: Text(_imageSaved
                      ? context.lang.shareImagedEditorSavedImage
                      : context.lang.shareImagedEditorSaveImage),
                ),
                const SizedBox(width: 20),
                FilledButton.icon(
                  icon: FaIcon(FontAwesomeIcons.solidPaperPlane),
                  onPressed: () {
                    Future<Uint8List?> imageBytes = getMergedImage();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShareImageView(
                          imageBytesFuture: imageBytes,
                          isRealTwonly: _isRealTwonly,
                          maxShowTime: _maxShowTime,
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
                    context.lang.shareImagedEditorShareWith,
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
