import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/views/camera/share_image_editor/action_button.dart';
import 'package:twonly/src/views/camera/share_image_editor/layer_data.dart';

/// Emoji layer
class EmojiLayer extends StatefulWidget {
  const EmojiLayer({
    required this.layerData,
    super.key,
    this.onUpdate,
  });
  final EmojiLayerData layerData;
  final VoidCallback? onUpdate;

  @override
  State<EmojiLayer> createState() => _EmojiLayerState();
}

class _EmojiLayerState extends State<EmojiLayer> {
  double initialRotation = 0;
  Offset initialOffset = Offset.zero;
  Offset initialFocalPoint = Offset.zero;
  double initialScale = 1;
  bool deleteLayer = false;
  bool twoPointerWhereDown = false;
  final GlobalKey outlineKey = GlobalKey();
  final GlobalKey emojiKey = GlobalKey();
  int pointers = 0;
  bool display = false;

  @override
  void initState() {
    super.initState();

    if (widget.layerData.offset.dy == 0) {
      // Set the initial offset to the center of the screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          widget.layerData.offset = Offset(
            MediaQuery.of(context).size.width / 2 - (153 / 2),
            MediaQuery.of(context).size.height / 2 - (153 / 2) - 100,
          );
        });
        display = true;
      });
    } else {
      display = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!display) return Container();
    if (widget.layerData.isDeleted) return Container();
    return Stack(
      key: outlineKey,
      children: [
        Positioned(
          left: widget.layerData.offset.dx,
          top: widget.layerData.offset.dy,
          child: PhysicalModel(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(180),
            clipBehavior: Clip.antiAlias,
            child: Listener(
              onPointerUp: (details) {
                setState(() {
                  pointers--;
                  if (pointers == 0) {
                    twoPointerWhereDown = false;
                  }
                  if (deleteLayer) {
                    widget.layerData.isDeleted = true;
                    widget.onUpdate!();
                  }
                });
              },
              onPointerDown: (details) {
                setState(() {
                  pointers++;
                });
              },
              child: GestureDetector(
                onScaleStart: (details) {
                  initialScale = widget.layerData.size;
                  initialRotation = widget.layerData.rotation;
                  initialOffset = widget.layerData.offset;
                  initialFocalPoint =
                      Offset(details.focalPoint.dx, details.focalPoint.dy);

                  setState(() {});
                },
                onScaleUpdate: (details) async {
                  if (twoPointerWhereDown && details.pointerCount != 2) {
                    return;
                  }
                  final outlineBox = outlineKey.currentContext!
                      .findRenderObject()! as RenderBox;

                  final emojiBox =
                      emojiKey.currentContext!.findRenderObject()! as RenderBox;

                  final isAtTheBottom =
                      (widget.layerData.offset.dy + emojiBox.size.height / 2) >
                          outlineBox.size.height - 80;
                  final isInTheCenter =
                      MediaQuery.of(context).size.width / 2 - 30 <
                              (widget.layerData.offset.dx +
                                  emojiBox.size.width / 2) &&
                          MediaQuery.of(context).size.width / 2 + 20 >
                              (widget.layerData.offset.dx +
                                  emojiBox.size.width / 2);

                  if (isAtTheBottom && isInTheCenter) {
                    if (!deleteLayer) {
                      await HapticFeedback.heavyImpact();
                    }
                    deleteLayer = true;
                  } else {
                    deleteLayer = false;
                  }
                  setState(() {
                    twoPointerWhereDown = details.pointerCount >= 2;
                    widget.layerData.size = initialScale * details.scale;
                    // print(widget.layerData.size);
                    widget.layerData.rotation =
                        initialRotation + details.rotation;

                    // Update the position based on the translation
                    final dx = (initialOffset.dx) +
                        (details.focalPoint.dx - initialFocalPoint.dx);
                    final dy = (initialOffset.dy) +
                        (details.focalPoint.dy - initialFocalPoint.dy);
                    widget.layerData.offset = Offset(dx, dy);
                  });
                },
                child: Transform.rotate(
                  angle: widget.layerData.rotation,
                  key: emojiKey,
                  child: Container(
                    padding: const EdgeInsets.all(44),
                    color: Colors.transparent,
                    child: ScreenshotEmoji(
                      emoji: widget.layerData.text,
                      displaySize: widget.layerData.size,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (pointers > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: GestureDetector(
                child: ActionButton(
                  FontAwesomeIcons.trashCan,
                  tooltipText: '',
                  color: deleteLayer ? Colors.red : Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Workaround: https://github.com/twonlyapp/twonly-app/issues/349
class ScreenshotEmoji extends StatefulWidget {
  const ScreenshotEmoji({
    required this.emoji,
    required this.displaySize,
    super.key,
  });
  final String emoji;
  final double displaySize;

  @override
  State<ScreenshotEmoji> createState() => _ScreenshotEmojiState();
}

class _ScreenshotEmojiState extends State<ScreenshotEmoji> {
  final GlobalKey _boundaryKey = GlobalKey();
  ui.Image? _capturedImage;

  @override
  void initState() {
    super.initState();
    // Capture the emoji immediately after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureEmoji());
  }

  Future<void> _captureEmoji() async {
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 4);
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      Log.error('Error capturing emoji: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_capturedImage != null) {
      return SizedBox(
        width: widget.displaySize,
        height: widget.displaySize,
        child: RawImage(
          image: _capturedImage,
          fit: BoxFit.contain,
        ),
      );
    }

    return Stack(
      children: [
        Positioned(
          top: -200, // hide from the user as the size changes with the image
          child: RepaintBoundary(
            key: _boundaryKey,
            child: Text(
              widget.emoji,
              style: const TextStyle(fontSize: 94),
            ),
          ),
        ),
        SizedBox(width: widget.displaySize, height: widget.displaySize),
      ],
    );
  }
}
