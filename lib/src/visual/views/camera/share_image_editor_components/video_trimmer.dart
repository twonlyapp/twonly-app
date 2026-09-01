import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Cuts a recorded video down to the part the user wants to send.
///
/// The two handles move the ends of the clip and the line between them is the
/// playhead, which can be dragged to look through the recording. Nothing is
/// written while a handle is moving: [onChanged] keeps the preview in step and
/// [onChangeEnd] fires once the finger lifts, which is the point where the cut
/// is worth storing.
///
/// Playback is kept inside the selection here rather than by the editor,
/// because this is already the widget listening to the player's position.
class VideoTrimmer extends StatefulWidget {
  const VideoTrimmer({
    required this.controller,
    required this.start,
    required this.end,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  final VideoPlayerController controller;

  /// The current cut. Both are real positions in the recording; the editor
  /// resolves "not cut on this end" to zero and the full duration before
  /// handing them over.
  final Duration start;
  final Duration end;

  /// Called continuously while a handle is dragged.
  final void Function(Duration start, Duration end) onChanged;

  /// Called once, when the finger lifts.
  final void Function(Duration start, Duration end) onChangeEnd;

  /// Nothing shorter than this can be selected. A clip the length of a single
  /// frame is never what someone was aiming for, and it gives the two handles
  /// room to stay apart.
  static const Duration minimumSelection = Duration(seconds: 1);

  @override
  State<VideoTrimmer> createState() => _VideoTrimmerState();
}

/// What a drag started on.
enum _Grip { start, end, playhead }

class _VideoTrimmerState extends State<VideoTrimmer> {
  static const double _trackHeight = 40;
  static const double _handleWidth = 14;

  /// How far from a handle a touch still counts as grabbing it. Fingers are
  /// wider than the handles are drawn.
  static const double _grabSlop = 22;

  _Grip? _grip;

  /// Whether the clip was playing when the finger went down, so scrubbing can
  /// pause it and hand playback back the way it found it. Seeking against a
  /// running player fights the drag and makes the preview stutter.
  bool _resumeAfterDrag = false;

  /// Where the player is, mirrored so the playhead can be repainted without
  /// rebuilding the editor around it.
  Duration _position = Duration.zero;

  Duration get _duration => widget.controller.value.duration;

  @override
  void initState() {
    super.initState();
    _position = widget.controller.value.position;
    widget.controller.addListener(_onPlaybackChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlaybackChanged);
    super.dispose();
  }

  void _onPlaybackChanged() {
    if (!mounted) return;
    final position = widget.controller.value.position;

    // The player loops on the whole file, so the cut end has to bring it back
    // by hand. Done before the repaint so the playhead never draws past the
    // selection.
    if (_grip == null &&
        widget.controller.value.isPlaying &&
        (position >= widget.end || position < widget.start)) {
      unawaited(widget.controller.seekTo(widget.start));
      return;
    }

    if (position != _position) {
      setState(() => _position = position);
    }
  }

  Duration _positionAt(double dx, double width) {
    if (width <= 0 || _duration == Duration.zero) return Duration.zero;
    final fraction = (dx / width).clamp(0.0, 1.0);
    return Duration(
      milliseconds: (_duration.inMilliseconds * fraction).round(),
    );
  }

  double _offsetOf(Duration position, double width) {
    if (_duration == Duration.zero) return 0;
    final fraction = position.inMilliseconds / _duration.inMilliseconds;
    return fraction.clamp(0.0, 1.0) * width;
  }

  /// The handle or the playhead nearest to where the finger landed, as long as
  /// something is actually within reach.
  _Grip _gripFor(double dx, double width) {
    final distances = <_Grip, double>{
      _Grip.start: (dx - _offsetOf(widget.start, width)).abs(),
      _Grip.end: (dx - _offsetOf(widget.end, width)).abs(),
      _Grip.playhead: (dx - _offsetOf(_position, width)).abs(),
    };
    final nearest = distances.entries.reduce(
      (a, b) => a.value <= b.value ? a : b,
    );
    // Anywhere else on the track is a seek: tapping the middle of the clip to
    // jump there is more useful than dragging an end that was not aimed at.
    return nearest.value <= _grabSlop ? nearest.key : _Grip.playhead;
  }

  void _onDrag(double dx, double width) {
    final at = _positionAt(dx, width);
    switch (_grip) {
      case _Grip.start:
        final limit = widget.end - VideoTrimmer.minimumSelection;
        final start = at > limit ? limit : at;
        widget.onChanged(_atLeastZero(start), widget.end);
        unawaited(widget.controller.seekTo(_atLeastZero(start)));
      case _Grip.end:
        final limit = widget.start + VideoTrimmer.minimumSelection;
        final end = at < limit ? limit : at;
        final capped = end > _duration ? _duration : end;
        widget.onChanged(widget.start, capped);
        // Seeking to the very last frame tends to land on a black one, so the
        // preview shows the frame just before the new end instead.
        unawaited(
          widget.controller.seekTo(capped - const Duration(milliseconds: 40)),
        );
      case _Grip.playhead:
        final clamped = at < widget.start
            ? widget.start
            : (at > widget.end ? widget.end : at);
        setState(() => _position = clamped);
        unawaited(widget.controller.seekTo(clamped));
      case null:
        break;
    }
  }

  static Duration _atLeastZero(Duration value) =>
      value < Duration.zero ? Duration.zero : value;

  static String _format(Duration value) {
    final seconds = value.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_duration == Duration.zero) return const SizedBox.shrink();
    final selection = widget.end - widget.start;
    final isTrimmed =
        widget.start > Duration.zero ||
        widget.end < _duration - const Duration(milliseconds: 100);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        // Translucent rather than opaque: the frames being cut away stay
        // visible underneath, which is most of what makes a cut readable.
        color: Colors.black.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // The handles sit inside the ends of the track, so the positions
              // they can be dragged to are one handle narrower than the box.
              final width = constraints.maxWidth - _handleWidth * 2;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (details) {
                  _grip = _gripFor(
                    details.localPosition.dx - _handleWidth,
                    width,
                  );
                  _resumeAfterDrag = widget.controller.value.isPlaying;
                  if (_resumeAfterDrag) {
                    unawaited(widget.controller.pause());
                  }
                  _onDrag(details.localPosition.dx - _handleWidth, width);
                },
                onHorizontalDragUpdate: (details) =>
                    _onDrag(details.localPosition.dx - _handleWidth, width),
                onHorizontalDragEnd: (_) {
                  _grip = null;
                  widget.onChangeEnd(widget.start, widget.end);
                  if (_resumeAfterDrag) {
                    _resumeAfterDrag = false;
                    unawaited(widget.controller.play());
                  }
                },
                onTapUp: (details) {
                  _grip = _Grip.playhead;
                  _onDrag(details.localPosition.dx - _handleWidth, width);
                  _grip = null;
                },
                child: SizedBox(
                  height: _trackHeight,
                  child: _TrimTrack(
                    trackWidth: width,
                    handleWidth: _handleWidth,
                    startOffset: _offsetOf(widget.start, width),
                    endOffset: _offsetOf(widget.end, width),
                    playheadOffset: _offsetOf(_position, width),
                    accent: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            isTrimmed
                ? '${_format(widget.start)} – ${_format(widget.end)}  ·  ${_format(selection)}'
                : _format(_duration),
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withAlpha(isTrimmed ? 235 : 150),
              fontFeatures: const [FontFeature.tabularFigures()],
              shadows: const [
                Shadow(color: Color.fromARGB(122, 0, 0, 0), blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The bar itself: the whole recording, the selected span, and the playhead.
class _TrimTrack extends StatelessWidget {
  const _TrimTrack({
    required this.trackWidth,
    required this.handleWidth,
    required this.startOffset,
    required this.endOffset,
    required this.playheadOffset,
    required this.accent,
  });

  final double trackWidth;
  final double handleWidth;
  final double startOffset;
  final double endOffset;
  final double playheadOffset;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final selectionWidth = (endOffset - startOffset).clamp(0.0, trackWidth);

    return Stack(
      children: [
        // The recording in full, so the cut-off parts stay visible as the
        // context the selection was taken out of.
        Positioned.fill(
          left: handleWidth,
          right: handleWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(46),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Positioned(
          left: startOffset,
          width: selectionWidth + handleWidth * 2,
          top: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: accent.withAlpha(40),
              border: Border.symmetric(
                horizontal: BorderSide(color: accent, width: 2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        _handle(left: startOffset),
        _handle(left: endOffset + handleWidth),
        Positioned(
          left: playheadOffset + handleWidth - 1,
          top: 4,
          bottom: 4,
          width: 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              boxShadow: const [
                BoxShadow(color: Color.fromARGB(122, 0, 0, 0), blurRadius: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _handle({required double left}) {
    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      width: handleWidth,
      child: Center(
        child: Container(
          width: handleWidth,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Container(
              width: 2,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(220),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
