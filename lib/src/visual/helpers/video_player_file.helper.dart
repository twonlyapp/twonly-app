import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:twonly/src/utils/log.dart';
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
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  void _createController() {
    final controller = VideoPlayerController.file(
      widget.videoPath,
      videoPlayerOptions: VideoPlayerOptions(),
    );

    _controller = controller;
    _failed = false;
    unawaited(_initialize(controller));
  }

  bool _isCurrent(VideoPlayerController controller) =>
      mounted && identical(controller, _controller);

  Future<void> _initialize(VideoPlayerController controller) async {
    try {
      await controller.initialize();
      if (!_isCurrent(controller)) return;
      await controller.setLooping(true);
      if (!_isCurrent(controller)) return;
      await controller.play();
      if (!_isCurrent(controller)) return;
      setState(() {});
    } catch (error, stackTrace) {
      if (!_isCurrent(controller)) return;
      Log.warn('Could not open video preview', error, stackTrace);
      setState(() => _failed = true);
    }
  }

  Future<void> _disposeController(VideoPlayerController controller) async {
    try {
      await controller.dispose();
    } catch (error, stackTrace) {
      Log.warn('Could not release video preview', error, stackTrace);
    }
  }

  @override
  void didUpdateWidget(VideoPlayerFileHelper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath.path != widget.videoPath.path) {
      unawaited(_disposeController(_controller));
      _createController();
    }
  }

  @override
  void dispose() {
    unawaited(_disposeController(_controller));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _failed
          ? const Icon(Icons.broken_image_outlined)
          : _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayerHelper(controller: _controller),
            )
          : const CircularProgressIndicator.adaptive(),
    );
  }
}
