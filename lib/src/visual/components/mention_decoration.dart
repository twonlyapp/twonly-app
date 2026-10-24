import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:twonly/src/visual/components/mention_editing_controller.dart';

Color _backgroundColor(BuildContext context) => Colors.black.withValues(
  alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.1,
);

void _paintMention(Canvas canvas, Rect rect, Color color) {
  if (rect.isEmpty) return;
  final background = RRect.fromRectAndRadius(
    rect.inflate(1),
    const Radius.circular(4),
  );
  canvas.drawRRect(
    background,
    Paint()..color = color,
  );
}

/// Decorates real text instead of placeholders, preserving wrapping, semantics,
/// selection offsets, and the existing recognizers on mention spans.
class MentionBackground extends SingleChildRenderObjectWidget {
  const MentionBackground({
    required this.selections,
    required super.child,
    super.key,
  });

  final List<TextSelection> selections;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMentionBackground(selections, _backgroundColor(context));

  @override
  void updateRenderObject(
    BuildContext context,
    RenderObject renderObject,
  ) {
    (renderObject as _RenderMentionBackground)
      ..selections = selections
      ..color = _backgroundColor(context);
  }
}

class _RenderMentionBackground extends RenderProxyBox {
  _RenderMentionBackground(this._selections, this._color);
  List<TextSelection> _selections;
  Color _color;

  set color(Color value) {
    if (value == _color) return;
    _color = value;
    markNeedsPaint();
  }

  set selections(List<TextSelection> value) {
    if (listEquals(value, _selections)) return;
    _selections = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final paragraph = _findRenderObject<RenderParagraph>(child);
    if (paragraph != null && _selections.isNotEmpty) {
      final canvas = context.canvas
        ..save()
        ..translate(offset.dx, offset.dy)
        ..transform(paragraph.getTransformTo(this).storage);
      for (final selection in _selections) {
        for (final box in paragraph.getBoxesForSelection(selection)) {
          _paintMention(canvas, box.toRect(), _color);
        }
      }
      canvas.restore();
    }
    super.paint(context, offset);
  }
}

T? _findRenderObject<T extends RenderObject>(RenderObject? root) {
  if (root is T) return root;
  T? result;
  root?.visitChildren((child) => result ??= _findRenderObject<T>(child));
  return result;
}

/// Installs the same decoration beneath editable text, inside its own clipping
/// and scrolling area and above any input decoration fill.
class MentionInputBackground extends StatefulWidget {
  const MentionInputBackground({
    required this.controller,
    required this.child,
    super.key,
  });

  final MentionEditingController controller;
  final Widget child;

  @override
  State<MentionInputBackground> createState() => _MentionInputBackgroundState();
}

class _MentionInputBackgroundState extends State<MentionInputBackground> {
  final GlobalKey _fieldKey = GlobalKey();
  late _MentionEditablePainter _painter;
  RenderEditable? _editable;

  @override
  void initState() {
    super.initState();
    _painter = _MentionEditablePainter(widget.controller);
  }

  @override
  void didUpdateWidget(MentionInputBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detach();
      _painter.dispose();
      _painter = _MentionEditablePainter(widget.controller);
    }
  }

  void _detach() {
    final editable = _editable;
    if (editable != null &&
        editable.attached &&
        identical(editable.painter, _painter)) {
      editable.painter = null;
    }
    _editable = null;
  }

  @override
  void dispose() {
    _detach();
    _painter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _painter.color = _backgroundColor(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final editable = _findRenderObject<RenderEditable>(
        _fieldKey.currentContext?.findRenderObject(),
      );
      if (identical(editable, _editable)) return;
      _detach();
      _editable = editable;
      editable?.painter = _painter;
    });
    return KeyedSubtree(key: _fieldKey, child: widget.child);
  }
}

class _MentionEditablePainter extends RenderEditablePainter {
  _MentionEditablePainter(this.controller) {
    controller.addListener(notifyListeners);
  }

  final MentionEditingController controller;
  Color _color = Colors.black.withValues(alpha: 0.1);

  set color(Color value) {
    if (value == _color) return;
    _color = value;
    notifyListeners();
  }

  @override
  void paint(Canvas canvas, Size size, RenderEditable renderEditable) {
    for (final selection in controller.mentionSelections) {
      for (final box in renderEditable.getBoxesForSelection(selection)) {
        _paintMention(canvas, box.toRect(), _color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MentionEditablePainter? oldDelegate) =>
      oldDelegate?.controller != controller || oldDelegate?._color != _color;

  @override
  void dispose() {
    controller.removeListener(notifyListeners);
    super.dispose();
  }
}
