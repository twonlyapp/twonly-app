import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/components/media_view_sizing.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/share_image_view.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:twonly/src/components/image_editor/data/image_item.dart';
import 'package:twonly/src/components/image_editor/data/layer.dart';
import 'package:twonly/src/components/image_editor/layers_viewer.dart';
import 'package:twonly/src/components/image_editor/modules/all_emojis.dart';
import 'package:screenshot/screenshot.dart';
import 'package:hand_signature/signature.dart';

List<Layer> layers = [];
List<Layer> undoLayers = [];
List<Layer> removedLayers = [];

class ShareImageEditorView extends StatefulWidget {
  const ShareImageEditorView({super.key, required this.imageBytes});
  final Uint8List imageBytes;
  static List<Shadow> get iconShadow => [
        Shadow(
          color: const Color.fromARGB(122, 0, 0, 0),
          blurRadius: 5.0,
        )
      ];
  @override
  State<ShareImageEditorView> createState() => _ShareImageEditorView();
}

class _ShareImageEditorView extends State<ShareImageEditorView> {
  bool _imageSaved = false;

  ImageItem currentImage = ImageItem();
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    loadImage(widget.imageBytes);

    super.initState();
  }

  @override
  void dispose() {
    layers.clear();
    super.dispose();
  }

  List<Widget> get filterActions {
    return [
      IconButton(
        icon: FaIcon(FontAwesomeIcons.xmark,
            size: 30, shadows: ShareImageEditorView.iconShadow),
        color: Colors.white,
        onPressed: () async {
          Navigator.pop(context);
        },
      ),
      Expanded(child: Container()),
      IconButton(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        icon: FaIcon(FontAwesomeIcons.rotateLeft,
            color: layers.length > 1 || removedLayers.isNotEmpty
                ? Colors.white
                : Colors.grey,
            shadows: ShareImageEditorView.iconShadow),
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
      IconButton(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        icon: FaIcon(FontAwesomeIcons.rotateRight,
            color: undoLayers.isNotEmpty ? Colors.white : Colors.grey,
            shadows: ShareImageEditorView.iconShadow),
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

  /// obtain image Uint8List by merging layers
  Future<Uint8List?> getMergedImage() async {
    Uint8List? image;

    if (layers.length > 1) {
      image = await screenshotController.capture(pixelRatio: pixelRatio);
    } else if (layers.length == 1) {
      if (layers.first is BackgroundLayerData) {
        image = (layers.first as BackgroundLayerData).image.bytes;
      } else if (layers.first is ImageLayerData) {
        image = (layers.first as ImageLayerData).image.bytes;
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
                children: filterActions,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 100,
            child: Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    BottomButton(
                      icon: FontAwesomeIcons.font,
                      onTap: () async {
                        undoLayers.clear();
                        removedLayers.clear();
                        layers.add(TextLayerData());
                        setState(() {});
                      },
                    ),
                    SizedBox(height: 20),
                    BottomButton(
                      icon: FontAwesomeIcons.pencil,
                      onTap: () async {
                        var drawing = await Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (context, a, b) => ImageEditorDrawing(
                              image: currentImage,
                            ),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );

                        if (drawing != null) {
                          undoLayers.clear();
                          removedLayers.clear();

                          layers.add(
                            ImageLayerData(
                              image: ImageItem(drawing),
                              offset: Offset(0, 0),
                            ),
                          );

                          setState(() {});
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    BottomButton(
                      icon: FontAwesomeIcons.faceGrinWide,
                      onTap: () async {
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
                  ],
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
                  icon: _imageSaved
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
                    Uint8List? imageBytes = await getMergedImage();
                    if (imageBytes == null || !context.mounted) return;
                    final res = await saveImageToGallery(imageBytes);
                    if (res == null) {
                      setState(() {
                        _imageSaved = true;
                      });
                    }
                  },
                  label: Text(_imageSaved
                      ? AppLocalizations.of(context)!
                          .shareImagedEditorSavedImage
                      : AppLocalizations.of(context)!
                          .shareImagedEditorSaveImage),
                ),
                const SizedBox(width: 20),
                FilledButton.icon(
                  icon: FaIcon(FontAwesomeIcons.solidPaperPlane),
                  onPressed: () async {
                    Uint8List? imageBytes = await getMergedImage();
                    if (imageBytes == null || !context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ShareImageView(imageBytes: imageBytes)),
                    );
                  },
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all<EdgeInsets>(
                      EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    ),
                  ),
                  label: Text(
                    AppLocalizations.of(context)!.shareImagedEditorShareWith,
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

/// Button used in bottomNavigationBar in ImageEditor
class BottomButton extends StatelessWidget {
  final VoidCallback? onTap, onLongPress;
  final IconData icon;

  const BottomButton({
    super.key,
    this.onTap,
    this.onLongPress,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            FaIcon(
              icon,
              color: Colors.white,
              shadows: ShareImageEditorView.iconShadow,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Show image drawing surface over image
class ImageEditorDrawing extends StatefulWidget {
  final ImageItem image;

  const ImageEditorDrawing({
    super.key,
    required this.image,
  });

  @override
  State<ImageEditorDrawing> createState() => _ImageEditorDrawingState();
}

class _ImageEditorDrawingState extends State<ImageEditorDrawing> {
  Color pickerColor = Colors.white, currentColor = Colors.white;

  var screenshotController = ScreenshotController();

  final control = HandSignatureControl(
    threshold: 3.0,
    smoothRatio: 0.65,
    velocityRange: 2.0,
  );

  List<CubicPath> undoList = [];
  bool skipNextEvent = false;

  // void changeColor(Colors color) {
  //   currentColor = color.color;
  //   currentBackgroundColor = color.background;

  //   setState(() {});
  // }

  @override
  void initState() {
    control.addListener(() {
      if (control.hasActivePath) return;

      if (skipNextEvent) {
        skipNextEvent = false;
        return;
      }

      undoList = [];
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.black,
      Colors.white,
      Colors.blue,
      Colors.green,
      Colors.pink,
      Colors.purple,
      Colors.brown,
      Colors.indigo,
    ];

    return Scaffold(
      backgroundColor: Colors.red.withAlpha(0),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              top: 0,
              child: Container(
                height: 600,
                width: 300,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(0, 210, 7, 7),
                ),
                // child: Container(),
                child: Screenshot(
                  controller: screenshotController,
                  // image: widget.options.showBackground
                  //     ? DecorationImage(
                  //         image: Image.memory(widget.image.bytes).image,
                  //         fit: BoxFit.contain,
                  //       )
                  //     : null,
                  // child: Container(),
                  child: HandSignature(
                    control: control,
                    color: currentColor,
                    width: 1.0,
                    maxWidth: 7.0,
                    type: SignatureDrawType.shape,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 100,
              right: 50,
              child: Column(
                children: [
                  IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    icon: Icon(
                      Icons.undo,
                      color: control.paths.isNotEmpty
                          ? Colors.white
                          : Colors.white.withAlpha(80),
                    ),
                    onPressed: () {
                      if (control.paths.isEmpty) return;
                      skipNextEvent = true;
                      undoList.add(control.paths.last);
                      control.stepBack();
                      setState(() {});
                    },
                  ),
                  IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    icon: Icon(
                      Icons.redo,
                      color: undoList.isNotEmpty
                          ? Colors.white
                          : Colors.white.withAlpha(80),
                    ),
                    onPressed: () {
                      if (undoList.isEmpty) return;

                      control.paths.add(undoList.removeLast());
                      setState(() {});
                    },
                  ),
                  IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    icon: const Icon(Icons.check),
                    onPressed: () async {
                      if (control.paths.isEmpty) return Navigator.pop(context);

                      var data = await control.toImage(
                        color: currentColor,
                        height: widget.image.height,
                        width: widget.image.width,
                      );

                      if (!mounted) return;

                      return Navigator.pop(context, data!.buffer.asUint8List());

                      // var loadingScreen = showLoadingScreen(context);
                      // var image = await screenshotController.capture();
                      // loadingScreen.hide();

                      // if (!mounted) return;

                      // return Navigator.pop(context, image);
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              right: 0,
              top: 50,
              child: Container(
                child: Container(
                  // height: 80,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(130, 0, 0, 0),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Column(
                    children: <Widget>[
                      for (var color in colors)
                        ColorButton(
                          color: color,
                          onTap: (color) {
                            currentColor = color;
                            setState(() {});
                          },
                          isSelected: color == currentColor,
                        ),
                    ],
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

class ColorButton extends StatelessWidget {
  final Color color;
  final Function(Color) onTap;
  final bool isSelected;

  const ColorButton({
    super.key,
    required this.color,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap(color);
      },
      child: Container(
        height: 17,
        width: 17,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white54,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}
