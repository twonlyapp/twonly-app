import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/action_button.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';

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
        if (!mounted) return;
        setState(() {
          widget.layerData.offset = Offset(
            MediaQuery.of(context).size.width / 2 - (153 / 2),
            MediaQuery.of(context).size.height / 2 - (153 / 2) - 100,
          );
          display = true;
        });
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
                  pointers = pointers > 0 ? pointers - 1 : 0;
                  if (pointers == 0) {
                    twoPointerWhereDown = false;
                    if (deleteLayer) {
                      widget.layerData.isDeleted = true;
                      widget.onUpdate?.call();
                    }
                  }
                });
              },
              onPointerCancel: (_) {
                setState(() {
                  pointers = 0;
                  twoPointerWhereDown = false;
                  deleteLayer = false;
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
                  initialFocalPoint = Offset(
                    details.focalPoint.dx,
                    details.focalPoint.dy,
                  );

                  setState(() {});
                },
                onScaleUpdate: (details) {
                  if (twoPointerWhereDown && details.pointerCount != 2) {
                    return;
                  }
                  final outlineBox =
                      outlineKey.currentContext!.findRenderObject()!
                          as RenderBox;

                  final size = initialScale * details.scale;
                  final offset =
                      initialOffset + (details.focalPoint - initialFocalPoint);
                  // Include the 44px touch padding on each side. Test the new
                  // position so trash feedback follows this gesture event.
                  final center =
                      offset + Offset((size + 88) / 2, (size + 88) / 2);
                  final overDelete =
                      center.dy > outlineBox.size.height - 80 &&
                      center.dx > outlineBox.size.width / 2 - 30 &&
                      center.dx < outlineBox.size.width / 2 + 20;
                  if (overDelete && !deleteLayer) {
                    HapticFeedback.heavyImpact();
                  }
                  setState(() {
                    deleteLayer = overDelete;
                    twoPointerWhereDown = details.pointerCount >= 2;
                    widget.layerData.size = size;
                    widget.layerData.rotation =
                        initialRotation + details.rotation;
                    widget.layerData.offset = offset;
                  });
                },
                child: Transform.rotate(
                  angle: widget.layerData.rotation,
                  key: emojiKey,
                  child: Container(
                    padding: const EdgeInsets.all(44),
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: deleteLayer ? 0.5 : 1,
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
                  color: deleteLayer
                      ? context.appColor(AppColor.recording)
                      : context.appColor(AppColor.mediaForeground),
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
  // Keep the font at the size used by the original workaround. Increasing the
  // font size itself can make color emoji disappear on Flutter.
  static const _fontSize = 94.0;
  static const _maxImageSize = 2048;
  ui.Image? _capturedImage;
  int _capturedSize = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _captureEmoji();
  }

  @override
  void didUpdateWidget(covariant ScreenshotEmoji oldWidget) {
    super.didUpdateWidget(oldWidget);
    _captureEmoji(force: oldWidget.emoji != widget.emoji);
  }

  void _captureEmoji({bool force = false}) {
    final requiredSize =
        widget.displaySize * MediaQuery.devicePixelRatioOf(context);
    // Grow in steps so a pinch gesture only creates a few images. Keep the
    // larger image when shrinking, and cap GPU memory for extreme zoom levels.
    var imageSize = 512;
    while (imageSize < requiredSize && imageSize < _maxImageSize) {
      imageSize *= 2;
    }
    if (!force && _capturedSize >= imageSize) return;

    final painter = TextPainter(
      text: TextSpan(
        text: widget.emoji,
        style: DefaultTextStyle.of(context).style.merge(
          TextStyle(
            fontSize: _fontSize,
            fontFamily: Platform.isAndroid ? 'NotoColorEmoji' : null,
          ),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    try {
      painter.layout();
      if (painter.size.isEmpty) return;

      final longestSide = painter.width > painter.height
          ? painter.width
          : painter.height;
      final pixelRatio = imageSize / longestSide;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(pixelRatio);
      painter.paint(canvas, Offset.zero);
      final picture = recorder.endRecording();
      late ui.Image image;
      try {
        // Record the glyph directly instead of relying on an offscreen widget.
        // The image handle is ready for this frame, including editor exports.
        image = picture.toImageSync(
          (painter.width * pixelRatio).ceil(),
          (painter.height * pixelRatio).ceil(),
        );
      } finally {
        picture.dispose();
      }
      _capturedImage?.dispose();
      _capturedImage = image;
      _capturedSize = imageSize;
    } catch (e) {
      Log.error('Error capturing emoji: $e');
    } finally {
      painter.dispose();
    }
  }

  @override
  void dispose() {
    _capturedImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawImage(
    image: _capturedImage,
    width: widget.displaySize,
    height: widget.displaySize,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
  );
}
