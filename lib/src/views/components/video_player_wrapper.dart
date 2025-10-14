import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWrapper extends StatefulWidget {
  const VideoPlayerWrapper({
    required this.videoPath,
    required this.mirrorVideo,
    super.key,
  });
  final File videoPath;
  final bool mirrorVideo;

  @override
  State<VideoPlayerWrapper> createState() => _VideoPlayerWrapperState();
}

class _VideoPlayerWrapperState extends State<VideoPlayerWrapper> {
  late VideoPlayerController _controller;

  @override
  Future<void> initState() async {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoPath);

    await _controller.initialize().then((_) async {
      if (context.mounted) {
        await _controller.setLooping(true);
        await _controller.play();
        setState(() {});
      }
    });
  }

  @override
  Future<void> dispose() async {
    await _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Transform.flip(
                flipX: widget.mirrorVideo,
                child: VideoPlayer(_controller),
              ),
            )
          : const CircularProgressIndicator(), // Show loading indicator while initializing
    );
  }
}
