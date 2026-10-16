import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/action_button.dart';

enum _SelectionDragMode {
  newSelection,
  move,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// An editor overlay for choosing the part of the canvas that becomes a
/// sticker. Dragging outside the current frame starts a new selection.
class StickerCutoutSelector extends StatefulWidget {
  const StickerCutoutSelector({
    required this.busy,
    required this.onCancel,
    required this.onConfirm,
    super.key,
  });

  final bool busy;
  final VoidCallback onCancel;
  final Future<void> Function(Rect selection, Size editorSize) onConfirm;

  @override
  State<StickerCutoutSelector> createState() => _StickerCutoutSelectorState();
}

class _StickerCutoutSelectorState extends State<StickerCutoutSelector> {
  static const _minimumSelection = 56.0;
  static const _handleHitRadius = 34.0;

  Rect? _selection;
  Rect _selectionAtDragStart = Rect.zero;
  Offset _dragStart = Offset.zero;
  _SelectionDragMode _dragMode = _SelectionDragMode.move;

  Rect _initialSelection(Size size) {
    final width = math.max(
      _minimumSelection,
      math.min(size.width * 0.62, size.width - 32),
    );
    final height = math.max(
      _minimumSelection,
      math.min(size.height * 0.38, size.height - 120),
    );
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: width,
      height: height,
    );
  }

  _SelectionDragMode _modeFor(Offset point, Rect selection) {
    final corners = <(_SelectionDragMode, Offset)>[
      (_SelectionDragMode.topLeft, selection.topLeft),
      (_SelectionDragMode.topRight, selection.topRight),
      (_SelectionDragMode.bottomLeft, selection.bottomLeft),
      (_SelectionDragMode.bottomRight, selection.bottomRight),
    ];
    for (final corner in corners) {
      if ((point - corner.$2).distance <= _handleHitRadius) return corner.$1;
    }
    return selection.contains(point)
        ? _SelectionDragMode.move
        : _SelectionDragMode.newSelection;
  }

  Offset _boundedPoint(Offset point, Size size) => Offset(
    point.dx.clamp(0, size.width),
    point.dy.clamp(0, size.height),
  );

  Rect _moveSelection(Offset delta, Size size) {
    var moved = _selectionAtDragStart.shift(delta);
    if (moved.left < 0) moved = moved.shift(Offset(-moved.left, 0));
    if (moved.top < 0) moved = moved.shift(Offset(0, -moved.top));
    if (moved.right > size.width) {
      moved = moved.shift(Offset(size.width - moved.right, 0));
    }
    if (moved.bottom > size.height) {
      moved = moved.shift(Offset(0, size.height - moved.bottom));
    }
    return moved;
  }

  Rect _resizeSelection(Offset point, Size size) {
    final bounded = _boundedPoint(point, size);
    final start = _selectionAtDragStart;
    return switch (_dragMode) {
      _SelectionDragMode.topLeft => Rect.fromLTRB(
        math.min(bounded.dx, start.right - _minimumSelection),
        math.min(bounded.dy, start.bottom - _minimumSelection),
        start.right,
        start.bottom,
      ),
      _SelectionDragMode.topRight => Rect.fromLTRB(
        start.left,
        math.min(bounded.dy, start.bottom - _minimumSelection),
        math.max(bounded.dx, start.left + _minimumSelection),
        start.bottom,
      ),
      _SelectionDragMode.bottomLeft => Rect.fromLTRB(
        math.min(bounded.dx, start.right - _minimumSelection),
        start.top,
        start.right,
        math.max(bounded.dy, start.top + _minimumSelection),
      ),
      _SelectionDragMode.bottomRight => Rect.fromLTRB(
        start.left,
        start.top,
        math.max(bounded.dx, start.left + _minimumSelection),
        math.max(bounded.dy, start.top + _minimumSelection),
      ),
      _ => start,
    };
  }

  Rect _newSelection(Offset point, Size size) {
    final bounded = _boundedPoint(point, size);
    var left = math.min(_dragStart.dx, bounded.dx);
    var top = math.min(_dragStart.dy, bounded.dy);
    var right = math.max(_dragStart.dx, bounded.dx);
    var bottom = math.max(_dragStart.dy, bounded.dy);
    if (right - left < _minimumSelection) {
      if (_dragStart.dx + _minimumSelection <= size.width) {
        right = left + _minimumSelection;
      } else {
        left = math.max(0, right - _minimumSelection);
      }
    }
    if (bottom - top < _minimumSelection) {
      if (_dragStart.dy + _minimumSelection <= size.height) {
        bottom = top + _minimumSelection;
      } else {
        top = math.max(0, bottom - _minimumSelection);
      }
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _onPanStart(DragStartDetails details, Size size) {
    if (widget.busy) return;
    final selection = _selection ?? _initialSelection(size);
    _dragStart = _boundedPoint(details.localPosition, size);
    _selectionAtDragStart = selection;
    _dragMode = _modeFor(_dragStart, selection);
    if (_dragMode == _SelectionDragMode.newSelection) {
      _selectionAtDragStart = Rect.fromLTWH(
        _dragStart.dx,
        _dragStart.dy,
        _minimumSelection,
        _minimumSelection,
      );
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (widget.busy) return;
    final point = _boundedPoint(details.localPosition, size);
    setState(() {
      _selection = switch (_dragMode) {
        _SelectionDragMode.move => _moveSelection(point - _dragStart, size),
        _SelectionDragMode.newSelection => _newSelection(point, size),
        _ => _resizeSelection(point, size),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final selection = _selection ??= _initialSelection(size);
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              key: const Key('stickerCutoutSelection'),
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) => _onPanStart(details, size),
              onPanUpdate: (details) => _onPanUpdate(details, size),
              child: CustomPaint(
                painter: _StickerSelectionPainter(selection),
              ),
            ),
            Positioned(
              top: 5,
              left: 5,
              right: 50,
              child: Row(
                children: [
                  ActionButton(
                    FontAwesomeIcons.xmark,
                    key: const Key('stickerCutoutCancel'),
                    tooltipText: context.lang.cancel,
                    disable: widget.busy,
                    onPressed: widget.onCancel,
                  ),
                  const Spacer(),
                  ActionButton(
                    FontAwesomeIcons.check,
                    key: const Key('stickerCutoutConfirm'),
                    tooltipText: context.lang.createStickerFromImage,
                    disable: widget.busy,
                    onPressed: () => widget.onConfirm(selection, size),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 62,
              left: 28,
              right: 28,
              child: IgnorePointer(
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Text(
                        context.lang.stickerSelectionHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.busy)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 14),
                        Text(
                          context.lang.stickerCreating,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StickerSelectionPainter extends CustomPainter {
  const _StickerSelectionPainter(this.selection);

  final Rect selection;

  @override
  void paint(Canvas canvas, Size size) {
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(selection, const Radius.circular(12)));
    final selectionShape = RRect.fromRectAndRadius(
      selection,
      const Radius.circular(12),
    );
    canvas
      ..drawPath(outside, Paint()..color = Colors.black54)
      ..drawRRect(
        selectionShape,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    for (final corner in [
      selection.topLeft,
      selection.topRight,
      selection.bottomLeft,
      selection.bottomRight,
    ]) {
      canvas.drawCircle(corner, 7, handlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StickerSelectionPainter oldDelegate) =>
      selection != oldDelegate.selection;
}
