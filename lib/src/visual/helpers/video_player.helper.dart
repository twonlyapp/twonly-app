import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerHelper extends StatefulWidget {
  const VideoPlayerHelper({
    required this.controller,
    this.onDoubleTap,
    super.key,
  });

  final VideoPlayerController controller;
  final VoidCallback? onDoubleTap;

  @override
  State<VideoPlayerHelper> createState() => _VideoPlayerHelperState();
}

class _VideoPlayerHelperState extends State<VideoPlayerHelper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconAnim;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _iconAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Opacity: flash in quickly, hold, fade out
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 55),
    ]).animate(_iconAnim);

    // Scale: pop in slightly over-sized then settle
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.15), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1), weight: 65),
    ]).animate(CurvedAnimation(parent: _iconAnim, curve: Curves.easeOut));

    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    final paused = !widget.controller.value.isPlaying;
    if (paused != _isPaused && mounted) {
      setState(() => _isPaused = paused);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _iconAnim.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
    _iconAnim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: widget.onDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(widget.controller),
          AnimatedBuilder(
            animation: _iconAnim,
            builder: (context, _) {
              // While paused and the flash has finished, show a dim persistent icon
              final opacity = _iconAnim.isAnimating
                  ? _opacity.value
                  : (_isPaused ? 0.1 : 0.0);
              final scale = _iconAnim.isAnimating ? _scale.value : 1.0;

              if (opacity == 0.0) return const SizedBox.shrink();

              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPaused
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
