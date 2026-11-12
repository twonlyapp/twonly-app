import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';

/// A heavily blurred copy of the memory filling the screen behind it, so the
/// space around media that does not fill the screen takes on its colors
/// instead of staying black.
///
/// When the memory changes, the previous blur stays fully visible underneath
/// until the new one has decoded and faded in on top, so the colors blend
/// directly into each other without passing through black.
class ViewerBlurredBackdropComp extends StatefulWidget {
  const ViewerBlurredBackdropComp({required this.media, super.key});

  final MediaFileService media;

  @override
  State<ViewerBlurredBackdropComp> createState() =>
      _ViewerBlurredBackdropCompState();
}

class _ViewerBlurredBackdropCompState extends State<ViewerBlurredBackdropComp> {
  /// The blur that is fully shown, kept below while [_current] fades in.
  MediaFileService? _previous;
  late MediaFileService _current = widget.media;
  bool _currentShown = false;

  @override
  void didUpdateWidget(covariant ViewerBlurredBackdropComp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.media.mediaFile.mediaId == _current.mediaFile.mediaId) return;
    // While swiping fast, keep the last blur that actually made it on screen.
    if (_currentShown) _previous = _current;
    _current = widget.media;
    _currentShown = false;
  }

  void _onCurrentShown(String mediaId) {
    if (!mounted || _currentShown || mediaId != _current.mediaFile.mediaId) {
      return;
    }
    setState(() {
      _currentShown = true;
      _previous = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final previous = _previous;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (previous != null)
          _BlurLayer(
            key: ValueKey(previous.mediaFile.mediaId),
            media: previous,
          ),
        _BlurLayer(
          key: ValueKey(_current.mediaFile.mediaId),
          media: _current,
          onShown: _onCurrentShown,
        ),
        // Dimmed, so the media itself and the controls stay in front.
        ColoredBox(
          color: context
              .appColor(AppColor.mediaBackground)
              .withValues(alpha: 0.45),
        ),
      ],
    );
  }
}

class _BlurLayer extends StatelessWidget {
  const _BlurLayer({required this.media, this.onShown, super.key});

  final MediaFileService media;

  /// Called with the media id once the layer is fully visible.
  final void Function(String mediaId)? onShown;

  static const double _sigma = 60;
  static const Duration _fadeIn = Duration(milliseconds: 250);

  /// Kept tiny: the blur removes all detail anyway, and decoding a small image
  /// on every swipe stays cheap.
  static const int _decodeWidth = 64;

  File? _source() {
    bool readable(File file) {
      final stat = file.statSync();
      return stat.type != FileSystemEntityType.notFound && stat.size > 0;
    }

    if (readable(media.thumbnailPath)) return media.thumbnailPath;
    final type = media.mediaFile.type;
    if ((type == MediaType.image || type == MediaType.gif) &&
        readable(media.storedPath)) {
      return media.storedPath;
    }
    return null;
  }

  void _notifyShown({Duration delay = Duration.zero}) {
    final callback = onShown;
    if (callback == null) return;
    final mediaId = media.mediaFile.mediaId;
    if (delay > Duration.zero) {
      Future<void>.delayed(delay, () => callback(mediaId));
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => callback(mediaId));
  }

  @override
  Widget build(BuildContext context) {
    final source = _source();
    if (source != null) {
      return ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: _sigma,
          sigmaY: _sigma,
          tileMode: TileMode.mirror,
        ),
        child: Image.file(
          source,
          fit: BoxFit.cover,
          cacheWidth: _decodeWidth,
          filterQuality: FilterQuality.low,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              _notifyShown();
              return child;
            }
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: _fadeIn,
              curve: Curves.easeOut,
              onEnd: frame == null ? null : _notifyShown,
              child: child,
            );
          },
          // Leaves the previous blur visible instead of showing black.
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    }

    final blurhash = media.mediaFile.blurhash;
    if (blurhash != null) {
      // The blurhash decodes asynchronously; keep the previous blur until
      // it had time to appear.
      _notifyShown(delay: const Duration(milliseconds: 300));
      // A blurhash is already a blurred version of the image.
      return BlurHash(
        hash: blurhash,
        optimizationMode: BlurHashOptimizationMode.approximation,
      );
    }

    return const SizedBox.shrink();
  }
}
