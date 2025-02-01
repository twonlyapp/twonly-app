import 'dart:async';
import 'dart:math' as math;
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hand_signature/signature.dart';
import 'package:twonly/src/components/image_editor/data/image_item.dart';
import 'package:twonly/src/components/image_editor/data/layer.dart';
import 'package:twonly/src/components/image_editor/layers_viewer.dart';
import 'package:twonly/src/components/image_editor/loading_screen.dart';
import 'package:twonly/src/components/image_editor/modules/all_emojis.dart';
import 'package:twonly/src/components/image_editor/modules/text.dart';
import 'package:twonly/src/components/image_editor/options.dart' as o;
import 'package:screenshot/screenshot.dart';

late Size viewportSize;
double viewportRatio = 1;

List<Layer> layers = [], undoLayers = [], removedLayers = [];
Map<String, String> _translations = {};

String i18n(String sourceString) =>
    _translations[sourceString.toLowerCase()] ?? sourceString;

/// Image editor with all option available
class ImageEditor extends StatefulWidget {
  final dynamic image;
  final String? savePath;
  final o.BrushOption? brushOption;
  final o.EmojiOption? emojiOption;
  final o.TextOption? textOption;

  const ImageEditor({
    super.key,
    this.image,
    this.savePath,
    this.brushOption = const o.BrushOption(),
    this.emojiOption = const o.EmojiOption(),
    this.textOption = const o.TextOption(),
  });

  @override
  createState() => _ImageEditorState();

  static setI18n(Map<String, String> translations) {
    translations.forEach((key, value) {
      _translations[key.toLowerCase()] = value;
    });
  }

  /// Set custom theme properties default is dark theme with white text
  static ThemeData theme = ThemeData(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      surface: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black87,
      iconTheme: IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      toolbarTextStyle: TextStyle(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
    ),
  );
}

class _ImageEditorState extends State<ImageEditor> {
  ImageItem currentImage = ImageItem();

  ScreenshotController screenshotController = ScreenshotController();

  @override
  void dispose() {
    layers.clear();
    super.dispose();
  }

  List<Widget> get filterActions {
    return [
      IconButton(
        icon: Icon(Icons.close, size: 30),
        color: Colors.white,
        onPressed: () async {
          Navigator.pop(context);
        },
      ),
      SizedBox(
        width: MediaQuery.of(context).size.width - 48,
        child: Row(children: [
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            icon: Icon(Icons.undo,
                color: layers.length > 1 || removedLayers.isNotEmpty
                    ? Colors.white
                    : Colors.grey),
            onPressed: () {
              if (removedLayers.isNotEmpty) {
                layers.add(removedLayers.removeLast());
                setState(() {});
                return;
              }

              if (layers.length <= 1) return; // do not remove image layer

              undoLayers.add(layers.removeLast());

              setState(() {});
            },
          ),
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            icon: Icon(Icons.redo,
                color: undoLayers.isNotEmpty ? Colors.white : Colors.grey),
            onPressed: () {
              if (undoLayers.isEmpty) return;

              layers.add(undoLayers.removeLast());

              setState(() {});
            },
          ),
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            icon: const Icon(Icons.check),
            onPressed: () async {
              resetTransformation();
              setState(() {});

              var loadingScreen = showLoadingScreen(context);

              Uint8List? editedImageBytes = await getMergedImage();

              loadingScreen.hide();

              if (mounted) Navigator.pop(context, editedImageBytes);
            },
          ),
        ]),
      ),
    ];
  }

  @override
  void initState() {
    if (widget.image != null) {
      loadImage(widget.image!);
    }

    super.initState();
  }

  double lastScaleFactor = 1, scaleFactor = 1;
  double widthRatio = 1, heightRatio = 1, pixelRatio = 1;

  resetTransformation() {
    scaleFactor = 1;
    setState(() {});
  }

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

  @override
  Widget build(BuildContext context) {
    viewportSize = MediaQuery.of(context).size;
    pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return Stack(children: [
      GestureDetector(
        onScaleUpdate: (details) {
          // print(details);

          // move
          if (details.pointerCount == 1) {
            // print(details.focalPointDelta);
            // x += details.focalPointDelta.dx;
            // y += details.focalPointDelta.dy;
            setState(() {});
          }

          // scale
          if (details.pointerCount == 2) {
            // print([details.horizontalScale, details.verticalScale]);
            if (details.horizontalScale != 1) {
              scaleFactor = lastScaleFactor *
                  math.min(details.horizontalScale, details.verticalScale);
              setState(() {});
            }
          }
        },
        onScaleEnd: (details) {
          lastScaleFactor = scaleFactor;
        },
        child: SizedBox(
          height: currentImage.height / pixelRatio,
          width: currentImage.width / pixelRatio,
          child: Screenshot(
            controller: screenshotController,
            child: LayersViewer(
              layers: layers,
              onUpdate: () {
                setState(() {});
              },
              editable: true,
            ),
          ),
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(75),
          ),
          child: SafeArea(
            child: Row(
              children: filterActions,
            ),
          ),
        ),
      ),
      Positioned(
        right: 0,
        top: 50,
        child: Container(
          // color: Colors.black45,
          alignment: Alignment.bottomCenter,
          // height: 86 + MediaQuery.of(context).padding.bottom,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
              // color: Colors.black87,
              // shape: BoxShape.rectangle,
              //   boxShadow: [
              //     BoxShadow(blurRadius: 1),
              //   ],
              ),
          child: SafeArea(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (widget.textOption != null)
                    BottomButton(
                      icon: Icons.text_fields,
                      onTap: () async {
                        TextLayerData? layer = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TextEditorImage(),
                          ),
                        );

                        if (layer == null) return;

                        undoLayers.clear();
                        removedLayers.clear();

                        layers.add(layer);

                        setState(() {});
                      },
                    ),
                  if (widget.brushOption != null)
                    BottomButton(
                      icon: Icons.edit,
                      onTap: () async {
                        if (widget.brushOption!.translatable) {
                          var drawing = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageEditorDrawing(
                                image: currentImage,
                                options: widget.brushOption!,
                              ),
                            ),
                          );

                          if (drawing != null) {
                            undoLayers.clear();
                            removedLayers.clear();

                            layers.add(
                              ImageLayerData(
                                image: ImageItem(drawing),
                                offset: Offset(
                                  -currentImage.width / 4,
                                  -currentImage.height / 4,
                                ),
                              ),
                            );

                            setState(() {});
                          }
                        } else {
                          resetTransformation();
                          var loadingScreen = showLoadingScreen(context);
                          var mergedImage = await getMergedImage();
                          loadingScreen.hide();

                          if (!mounted) return;

                          var drawing = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageEditorDrawing(
                                image: ImageItem(mergedImage!),
                                options: widget.brushOption!,
                              ),
                            ),
                          );

                          if (drawing != null) {
                            currentImage.load(drawing);

                            setState(() {});
                          }
                        }
                      },
                    ),
                  if (widget.emojiOption != null)
                    BottomButton(
                      icon: FontAwesomeIcons.faceSmile,
                      onTap: () async {
                        EmojiLayerData? layer = await showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.black,
                          builder: (BuildContext context) {
                            return const Emojies();
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
      ),
    ]);
  }

  Future<void> loadImage(dynamic imageFile) async {
    await currentImage.load(imageFile);

    layers.clear();

    layers.add(BackgroundLayerData(
      image: currentImage,
    ));

    setState(() {});
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
            Icon(
              icon,
              color: Colors.white,
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
  final o.BrushOption options;

  const ImageEditorDrawing({
    super.key,
    required this.image,
    this.options = const o.BrushOption(
      showBackground: true,
      translatable: true,
    ),
  });

  @override
  State<ImageEditorDrawing> createState() => _ImageEditorDrawingState();
}

class _ImageEditorDrawingState extends State<ImageEditorDrawing> {
  Color pickerColor = Colors.white,
      currentColor = Colors.white,
      currentBackgroundColor = Colors.black;
  var screenshotController = ScreenshotController();

  final control = HandSignatureControl(
    threshold: 3.0,
    smoothRatio: 0.65,
    velocityRange: 2.0,
  );

  List<CubicPath> undoList = [];
  bool skipNextEvent = false;

  void changeColor(o.BrushColor color) {
    currentColor = color.color;
    currentBackgroundColor = color.background;

    setState(() {});
  }

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
    return Theme(
      data: ImageEditor.theme,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: const Icon(Icons.clear),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const Spacer(),
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

                if (widget.options.translatable) {
                  var data = await control.toImage(
                    color: currentColor,
                    height: widget.image.height,
                    width: widget.image.width,
                  );

                  if (!mounted) return;

                  return Navigator.pop(context, data!.buffer.asUint8List());
                }

                var loadingScreen = showLoadingScreen(context);
                var image = await screenshotController.capture();
                loadingScreen.hide();

                if (!mounted) return;

                return Navigator.pop(context, image);
              },
            ),
          ],
        ),
        body: Screenshot(
          controller: screenshotController,
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color:
                  widget.options.showBackground ? null : currentBackgroundColor,
              image: widget.options.showBackground
                  ? DecorationImage(
                      image: Image.memory(widget.image.bytes).image,
                      fit: BoxFit.contain,
                    )
                  : null,
            ),
            child: HandSignature(
              control: control,
              color: currentColor,
              width: 1.0,
              maxWidth: 7.0,
              type: SignatureDrawType.shape,
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 80,
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(blurRadius: 2),
              ],
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                ColorButton(
                  color: Colors.yellow,
                  onTap: (color) {
                    showModalBottomSheet(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          topLeft: Radius.circular(10),
                        ),
                      ),
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(
                                MediaQuery.of(context).size.width / 2,
                              ),
                              topRight: Radius.circular(
                                MediaQuery.of(context).size.width / 2,
                              ),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: ColorPicker(
                              wheelDiameter:
                                  MediaQuery.of(context).size.width - 64,
                              color: currentColor,
                              pickersEnabled: const {
                                ColorPickerType.both: false,
                                ColorPickerType.primary: false,
                                ColorPickerType.accent: false,
                                ColorPickerType.bw: false,
                                ColorPickerType.custom: false,
                                ColorPickerType.customSecondary: false,
                                ColorPickerType.wheel: true,
                              },
                              enableShadesSelection: false,
                              onColorChanged: (color) {
                                currentColor = color;
                                setState(() {});
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                for (var color in widget.options.colors)
                  ColorButton(
                    color: color.color,
                    onTap: (color) {
                      currentColor = color;
                      setState(() {});
                    },
                    isSelected: color.color == currentColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Button used in bottomNavigationBar in ImageEditorDrawing
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
        height: 34,
        width: 34,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 23),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white54,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
