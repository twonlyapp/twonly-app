import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWrapper extends StatefulWidget {
  final File videoPath;
  final bool mirrorVideo;

  const VideoPlayerWrapper(
      {super.key, required this.videoPath, required this.mirrorVideo});

  @override
  State<VideoPlayerWrapper> createState() => _VideoPlayerWrapperState();
}

class _VideoPlayerWrapperState extends State<VideoPlayerWrapper> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoPath)
      ..initialize().then((_) {
        setState(() {
          _controller.setLooping(true);
          _controller.play();
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
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
          : CircularProgressIndicator(), // Show loading indicator while initializing
    );
  }
}
