import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:twonly/src/visual/helpers/video_player.helper.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerFileHelper extends StatefulWidget {
  const VideoPlayerFileHelper({
    required this.videoPath,
    super.key,
  });
  final File videoPath;

  @override
  State<VideoPlayerFileHelper> createState() => _VideoPlayerFileHelperState();
}

class _VideoPlayerFileHelperState extends State<VideoPlayerFileHelper> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(
      widget.videoPath,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
      ),
    );

    unawaited(
      _controller.initialize().then((_) async {
        if (context.mounted) {
          await _controller.setLooping(true);
          await _controller.play();
          setState(() {});
        }
      }),
    );
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayerHelper(controller: _controller),
            )
          : const CircularProgressIndicator(),
    );
  }
}
