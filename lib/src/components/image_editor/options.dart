import 'package:flutter/material.dart';

class BrushOption {
  /// show background image on draw screen
  final bool showBackground;

  /// User will able to move, zoom drawn image
  /// Note: Layer may not be placed precisely
  final bool translatable;
  final List<BrushColor> colors;

  const BrushOption({
    this.showBackground = true,
    this.translatable = false,
    this.colors = const [
      BrushColor(color: Colors.black, background: Colors.white),
      BrushColor(color: Colors.white),
      BrushColor(color: Colors.blue),
      BrushColor(color: Colors.green),
      BrushColor(color: Colors.pink),
      BrushColor(color: Colors.purple),
      BrushColor(color: Colors.brown),
      BrushColor(color: Colors.indigo),
    ],
  });
}

class BrushColor {
  /// Color of brush
  final Color color;

  /// Background color while brush is active only be used when showBackground is false
  final Color background;

  const BrushColor({
    required this.color,
    this.background = Colors.black,
  });
}

class EmojiOption {
  const EmojiOption();
}

class TextOption {
  const TextOption();
}
