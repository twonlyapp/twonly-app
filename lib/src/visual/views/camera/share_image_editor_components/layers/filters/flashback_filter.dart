import 'package:flutter/material.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/filter.layer.dart';

/// "One year ago", ... as a plain paper-like sticker, shown when a flashback
/// memory is shared. It is part of the media's pixels, so it keeps its own
/// colors regardless of the app theme.
class FlashbackFilter extends StatelessWidget {
  const FlashbackFilter({required this.label, super.key});

  final String label;

  static const _background = Color(0xFFFAF8F5);
  static const _ink = Color(0xFF1C1B1A);
  static const _inkMuted = Color(0xFF6B6863);

  /// A hairline, so the sticker still has an edge on bright photos.
  static const _outline = Color(0x1F000000);

  @override
  Widget build(BuildContext context) {
    return FilterSkeleton(
      child: Positioned(
        left: 24,
        right: 24,
        bottom: 110,
        child: Center(
          child: Transform.rotate(
            angle: -0.04,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _outline),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 9, 18, 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: _inkMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
