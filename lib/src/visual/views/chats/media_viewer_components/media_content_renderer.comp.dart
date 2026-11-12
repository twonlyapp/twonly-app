import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/photo_location_overlay.comp.dart';
import 'package:video_player/video_player.dart';

class MediaContentRenderer extends StatefulWidget {
  const MediaContentRenderer({
    required this.currentMedia,
    required this.videoController,
    required this.loader,
    this.videoFailed = false,
    this.photoLocation,
    super.key,
  });

  final MediaFileService? currentMedia;
  final VideoPlayerController? videoController;
  final Widget loader;
  final bool videoFailed;

  /// The location filter's map, drawn over the media.
  final PhotoLocationData? photoLocation;

  @override
  State<MediaContentRenderer> createState() => _MediaContentRendererState();
}

class _MediaContentRendererState extends State<MediaContentRenderer> {
  /// The map is placed on the unzoomed image, so it hides while zoomed.
  bool _zoomed = false;
  double? _imageAspectRatio;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  bool get _isImage {
    final type = widget.currentMedia?.mediaFile.type;
    return type == MediaType.image || type == MediaType.gif;
  }

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
  }

  @override
  void didUpdateWidget(covariant MediaContentRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMedia?.mediaFile.mediaId !=
            widget.currentMedia?.mediaFile.mediaId ||
        (oldWidget.photoLocation == null) != (widget.photoLocation == null)) {
      _zoomed = false;
      _resolveImageSize();
    }
  }

  @override
  void dispose() {
    _stopImageListener();
    super.dispose();
  }

  void _stopImageListener() {
    final listener = _imageListener;
    if (listener != null) _imageStream?.removeListener(listener);
    _imageStream = null;
    _imageListener = null;
  }

  /// Only needed to place the map, so nothing is resolved without one.
  void _resolveImageSize() {
    _stopImageListener();
    _imageAspectRatio = null;
    final media = widget.currentMedia;
    if (widget.photoLocation == null || media == null || !_isImage) return;
    final stream = FileImage(
      media.tempPath,
    ).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener((info, _) {
      final ratio = info.image.width / info.image.height;
      _stopImageListener();
      if (mounted) setState(() => _imageAspectRatio = ratio);
    }, onError: (_, _) => _stopImageListener());
    _imageStream = stream;
    _imageListener = listener;
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final videoController = widget.videoController;
    final currentMedia = widget.currentMedia;
    final videoReady =
        videoController != null && videoController.value.isInitialized;
    final location = widget.photoLocation;
    final aspectRatio = widget.videoFailed
        ? null
        : videoReady
        ? videoController.value.aspectRatio
        : _isImage
        ? _imageAspectRatio
        : null;
    return Stack(
      children: [
        if (widget.videoFailed)
          const Positioned.fill(
            child: Center(child: Icon(Icons.broken_image_outlined, size: 64)),
          )
        else if (videoReady)
          Positioned.fill(
            child: Center(
              child: AspectRatio(
                aspectRatio: videoController.value.aspectRatio,
                child: VideoPlayer(videoController),
              ),
            ),
          )
        else if (currentMedia != null && _isImage)
          Positioned.fill(
            child: PhotoView(
              key: ValueKey(currentMedia.mediaFile.mediaId),
              imageProvider: FileImage(
                currentMedia.tempPath,
              ),
              loadingBuilder: (context, event) => widget.loader,
              backgroundDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              scaleStateChangedCallback: (state) {
                final zoomed = state != PhotoViewScaleState.initial;
                if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: context.appColor(AppColor.mediaForegroundMuted),
                    size: 64,
                  ),
                );
              },
            ),
          ),
        if (location != null && aspectRatio != null && !_zoomed)
          Positioned.fill(
            child: PhotoLocationOverlay(
              key: ValueKey(currentMedia?.mediaFile.mediaId),
              location: location,
              mediaAspectRatio: aspectRatio,
            ),
          ),
      ],
    );
  }
}
