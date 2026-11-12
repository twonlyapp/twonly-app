import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/services/stickers.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/action_button.dart';

class _EraseStroke {
  _EraseStroke(this.width, Offset start) : points = [start];

  /// Brush diameter in sticker pixels, so strokes survive any display scale.
  final double width;
  final List<Offset> points;
}

/// Clears [strokes] out of [image] in sticker pixel coordinates. Display and
/// export share this so the result matches what the user saw.
void _paintErased(Canvas canvas, ui.Image image, List<_EraseStroke> strokes) {
  final bounds =
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble());
  canvas
    ..saveLayer(bounds, Paint())
    ..drawImage(
      image,
      Offset.zero,
      Paint()..filterQuality = FilterQuality.medium,
    );
  final erase = Paint()
    ..blendMode = BlendMode.clear
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  for (final stroke in strokes) {
    if (stroke.points.length == 1) {
      erase.style = PaintingStyle.fill;
      canvas.drawCircle(stroke.points.single, stroke.width / 2, erase);
    } else {
      erase
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.width;
      canvas.drawPath(Path()..addPolygon(stroke.points, false), erase);
    }
  }
  canvas.restore();
}

/// A full-screen brush for removing parts the segmentation kept, such as a
/// second person. Returns the re-encoded sticker, or null when the user
/// leaves without changes.
class StickerEraserView extends StatefulWidget {
  const StickerEraserView({required this.sticker, super.key});

  final StickerOutput sticker;

  static Route<StickerOutput> route(StickerOutput sticker) {
    return MaterialPageRoute(
      builder: (context) => StickerEraserView(sticker: sticker),
    );
  }

  @override
  State<StickerEraserView> createState() => _StickerEraserViewState();
}

class _StickerEraserViewState extends State<StickerEraserView> {
  static const _minBrush = 8.0;
  static const _maxBrush = 72.0;

  ui.Image? _image;
  final _strokes = <_EraseStroke>[];
  final _redo = <_EraseStroke>[];
  // Strokes grow in place, so the painter compares this instead of the list.
  int _revision = 0;
  double _brushSize = 28;
  int? _pointer;
  Offset? _cursor;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.sticker.webp);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } on Object {
      if (!mounted) return;
      setState(() => _error = context.lang.stickerEraseFailed);
    }
  }

  void _onPointerDown(PointerDownEvent event, double scale) {
    if (_busy || _pointer != null) return;
    _pointer = event.pointer;
    setState(() {
      _redo.clear();
      _strokes.add(
        _EraseStroke(_brushSize / scale, event.localPosition / scale),
      );
      _cursor = event.localPosition;
      _revision++;
    });
  }

  void _onPointerMove(PointerMoveEvent event, double scale) {
    if (event.pointer != _pointer) return;
    setState(() {
      _strokes.last.points.add(event.localPosition / scale);
      _cursor = event.localPosition;
      _revision++;
    });
  }

  void _onPointerEnd(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    setState(() => _cursor = null);
  }

  void _undo() {
    if (_busy || _strokes.isEmpty) return;
    setState(() {
      _redo.add(_strokes.removeLast());
      _revision++;
    });
  }

  void _redoStroke() {
    if (_busy || _redo.isEmpty) return;
    setState(() {
      _strokes.add(_redo.removeLast());
      _revision++;
    });
  }

  Future<void> _apply() async {
    final image = _image;
    if (_busy || image == null) return;
    if (_strokes.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final recorder = ui.PictureRecorder();
      _paintErased(Canvas(recorder), image, _strokes);
      final picture = recorder.endRecording();
      final rendered = await picture.toImage(image.width, image.height);
      picture.dispose();
      final png = await rendered.toByteData(format: ui.ImageByteFormat.png);
      rendered.dispose();
      if (png == null) throw StateError('could not render the erased sticker');
      final sticker = await RustApi.encodeEditedSticker(
        png: png.buffer.asUint8List(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(sticker);
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = context.lang.stickerEraseFailed;
      });
    }
  }

  Widget _buildCanvas(ui.Image image) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(
          constraints.maxWidth / image.width,
          constraints.maxHeight / image.height,
        );
        return Center(
          child: SizedBox(
            width: image.width * scale,
            height: image.height * scale,
            child: Listener(
              key: const Key('stickerEraserCanvas'),
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) => _onPointerDown(event, scale),
              onPointerMove: (event) => _onPointerMove(event, scale),
              onPointerUp: _onPointerEnd,
              onPointerCancel: _onPointerEnd,
              child: CustomPaint(
                painter: _EraserPainter(
                  image: image,
                  strokes: _strokes,
                  revision: _revision,
                  scale: scale,
                  cursor: _cursor,
                  brushSize: _brushSize,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final foreground = context.appColor(AppColor.mediaForeground);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: context.appColor(AppColor.mediaBackground),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      children: [
                        ActionButton(
                          FontAwesomeIcons.xmark,
                          key: const Key('stickerEraserCancel'),
                          tooltipText: context.lang.cancel,
                          disable: _busy,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            context.lang.stickerEraseTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: foreground),
                          ),
                        ),
                        ActionButton(
                          FontAwesomeIcons.arrowRotateLeft,
                          key: const Key('stickerEraserUndo'),
                          tooltipText: context.lang.undo,
                          disable: _busy || _strokes.isEmpty,
                          onPressed: _undo,
                        ),
                        ActionButton(
                          FontAwesomeIcons.arrowRotateRight,
                          key: const Key('stickerEraserRedo'),
                          tooltipText: context.lang.redo,
                          disable: _busy || _redo.isEmpty,
                          onPressed: _redoStroke,
                        ),
                        ActionButton(
                          FontAwesomeIcons.check,
                          key: const Key('stickerEraserApply'),
                          tooltipText: context.lang.stickerEraseApply,
                          disable: _busy || image == null,
                          onPressed: _apply,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    context.lang.stickerEraseHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appColor(AppColor.mediaForegroundMuted),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: image == null
                          ? const SizedBox.shrink()
                          : _buildCanvas(image),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.color.error),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: foreground),
                        Expanded(
                          child: Slider(
                            key: const Key('stickerEraserBrushSize'),
                            value: _brushSize,
                            min: _minBrush,
                            max: _maxBrush,
                            semanticFormatterCallback: (value) =>
                                '${context.lang.stickerEraseBrushSize} '
                                '${value.round()}',
                            activeColor: foreground,
                            // Show the brush in the middle of the sticker
                            // while its size changes.
                            onChangeStart: (_) => setState(
                              () => _cursor = Offset.infinite,
                            ),
                            onChanged: _busy
                                ? null
                                : (value) => setState(() => _brushSize = value),
                            onChangeEnd: (_) => setState(() => _cursor = null),
                          ),
                        ),
                        Icon(Icons.circle, size: 26, color: foreground),
                      ],
                    ),
                  ),
                ],
              ),
              if (_busy)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black54,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EraserPainter extends CustomPainter {
  const _EraserPainter({
    required this.image,
    required this.strokes,
    required this.revision,
    required this.scale,
    required this.cursor,
    required this.brushSize,
  });

  final ui.Image image;
  final List<_EraseStroke> strokes;
  final int revision;
  final double scale;

  /// The finger position in display coordinates; [Offset.infinite] centers
  /// the brush preview.
  final Offset? cursor;
  final double brushSize;

  @override
  void paint(Canvas canvas, Size size) {
    // A checkerboard makes erased areas read as transparent.
    const square = 12.0;
    final light = Paint()..color = const Color(0xFF3A3A3A);
    final dark = Paint()..color = const Color(0xFF262626);
    canvas
      ..save()
      ..clipRect(Offset.zero & size);
    for (var y = 0; y * square < size.height; y++) {
      for (var x = 0; x * square < size.width; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * square, y * square, square, square),
          (x + y).isEven ? light : dark,
        );
      }
    }
    canvas.scale(scale);
    _paintErased(canvas, image, strokes);
    canvas.restore();

    final cursor = this.cursor;
    if (cursor == null) return;
    final center = cursor.isInfinite ? size.center(Offset.zero) : cursor;
    canvas
      ..drawCircle(
        center,
        brushSize / 2,
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      )
      ..drawCircle(
        center,
        brushSize / 2,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
  }

  @override
  bool shouldRepaint(covariant _EraserPainter oldDelegate) =>
      image != oldDelegate.image ||
      revision != oldDelegate.revision ||
      scale != oldDelegate.scale ||
      cursor != oldDelegate.cursor ||
      brushSize != oldDelegate.brushSize;
}
