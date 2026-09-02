import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/visual/helpers/media_view_sizing.helper.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/main_camera_controller.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection.view.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/discard_media_dialog.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/display_time_picker.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/editor_bottom_bar.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/editor_canvas.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/editor_layer_stack.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/editor_media_writer.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/editor_side_toolbar.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/editor_top_toolbar.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/image_item.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/video_trimmer.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/widget_share_explainer.dart';
import 'package:video_player/video_player.dart';

/// Lets the user edit a just taken (or shared) photo/video/gif and send it.
///
/// The screen is built out of four parts:
/// * [EditorCanvas] shows the media with all edits stacked on top of it
/// * [EditorTopToolbar] holds close/undo/redo
/// * [EditorSideToolbar] holds the editing tools
/// * [EditorBottomBar] holds save to gallery and send
///
/// The edits themselves live in an [EditorLayerStack], writing them to disk is
/// done by an [EditorMediaWriter].
class ShareImageEditorView extends StatefulWidget {
  const ShareImageEditorView({
    required this.sharedFromGallery,
    required this.mediaFileService,
    this.screenshotImage,
    this.previewLink,
    super.key,
    this.sendToGroup,
    this.mainCameraController,
  });
  final ScreenshotImageHelper? screenshotImage;
  final Group? sendToGroup;
  final bool sharedFromGallery;
  final MediaFileService mediaFileService;
  final MainCameraController? mainCameraController;
  final PreviewLink? previewLink;
  @override
  State<ShareImageEditorView> createState() => _ShareImageEditorView();
}

class _ShareImageEditorView extends State<ShareImageEditorView> {
  final layerStack = EditorLayerStack();
  late final EditorMediaWriter mediaWriter;

  double tabDownPosition = 0;
  bool sendingOrLoadingImage = true;
  bool loadingImage = true;
  bool isDisposed = false;
  HashSet<String> selectedGroupIds = HashSet();
  double pixelRatio = 1;
  VideoPlayerController? videoController;

  /// The cut the trimmer is showing. Held here as well as in the media row so
  /// dragging a handle repaints immediately instead of waiting on a write, and
  /// so the send path and the preview always agree on the same bounds.
  Duration _trimStart = Duration.zero;

  /// Null until the trimmer is dragged or a stored cut is loaded; it then means
  /// "the clip ends here" while null keeps the recording's own end.
  Duration? _trimEnd;

  /// The cutter lies over the video, so it can be put away to see the frame
  /// underneath it. Open to begin with, otherwise nothing says it is there.
  bool _trimmerVisible = true;
  ImageItem currentImage = ImageItem();
  ScreenshotController screenshotController = ScreenshotController();
  Timer? _imageLoadingTimer;
  late final StreamSubscription<List<Group>> _widgetGroupsSubscription;
  final GlobalKey _editorStackKey = GlobalKey();
  final GlobalKey _widgetActionKey = GlobalKey();
  Offset? _widgetActionCenter;
  bool _widgetActionMeasurementScheduled = false;

  bool _widgetRecipientAvailable = false;
  bool _sendToWidget = false;
  bool _updatingWidgetMode = false;
  bool _widgetExplainerPreferenceLoaded = false;
  bool _widgetExplainerDismissed = false;
  bool _previousMediaSettingsCaptured = false;
  int? _displayLimitBeforeWidget;
  bool _requiresAuthBeforeWidget = false;

  bool get _showWidgetExplainer =>
      _widgetRecipientAvailable &&
      _widgetExplainerPreferenceLoaded &&
      !_widgetExplainerDismissed;

  MediaFileService get mediaService => widget.mediaFileService;
  MediaFile get media => widget.mediaFileService.mediaFile;

  @override
  void initState() {
    super.initState();

    mediaWriter = EditorMediaWriter(
      mediaService: mediaService,
      layerStack: layerStack,
      screenshotController: screenshotController,
      gifSource: widget.screenshotImage,
      requestRebuild: () {
        if (mounted) setState(() {});
      },
    );

    if (media.type != MediaType.gif) {
      layerStack.addFilterLayer();
    }

    final previewLink = widget.previewLink;
    if (previewLink != null && previewLink.shouldGeneratePreview) {
      layerStack.addLinkPreviewLayer(previewLink.url);
    }

    if (widget.sendToGroup != null) {
      selectedGroupIds.add(widget.sendToGroup!.groupId);
    }

    _widgetGroupsSubscription = twonlyDB.groupsDao
        .watchGroupsAllowedForWidgetShare()
        .listen(_updateWidgetRecipientAvailability);
    unawaited(_loadWidgetExplainerPreference());

    if (media.type == MediaType.image || media.type == MediaType.gif) {
      _loadInitialImage();
    }

    if (media.type == MediaType.video) {
      _initVideoController();
    }
  }

  @override
  void dispose() {
    isDisposed = true;
    layerStack.clear();
    videoController?.dispose();
    twonlyDB.mediaFilesDao.updateAllMediaFiles(
      const MediaFilesCompanion(
        isDraftMedia: Value(false),
      ),
    );
    _imageLoadingTimer?.cancel();
    unawaited(_widgetGroupsSubscription.cancel());
    super.dispose();
  }

  Future<void> _loadWidgetExplainerPreference() async {
    final preference = await KeyValueStore.get(
      KeyValueKeys.shareImageWidgetExplainer,
    );
    if (!mounted) return;
    setState(() {
      _widgetExplainerDismissed = preference?['dismissed'] == true;
      _widgetExplainerPreferenceLoaded = true;
    });
  }

  Future<void> _dismissWidgetExplainer() async {
    setState(() => _widgetExplainerDismissed = true);
    await KeyValueStore.put(
      KeyValueKeys.shareImageWidgetExplainer,
      const {'dismissed': true},
    );
  }

  void _updateWidgetRecipientAvailability(List<Group> widgetGroups) {
    final fixedGroupId = widget.sendToGroup?.groupId;
    final recipientAvailable =
        media.type == MediaType.image &&
        (fixedGroupId == null
            ? widgetGroups.isNotEmpty
            : widgetGroups.any((group) => group.groupId == fixedGroupId));

    if (mounted && recipientAvailable != _widgetRecipientAvailable) {
      setState(() => _widgetRecipientAvailable = recipientAvailable);
    }
    if (!recipientAvailable && _sendToWidget && !_updatingWidgetMode) {
      unawaited(_setSendToWidget(false));
    }
  }

  void _scheduleWidgetActionMeasurement() {
    if (_widgetActionMeasurementScheduled) return;
    _widgetActionMeasurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _widgetActionMeasurementScheduled = false;
      if (!mounted || !_showWidgetExplainer) return;

      final actionBox =
          _widgetActionKey.currentContext?.findRenderObject() as RenderBox?;
      final stackBox =
          _editorStackKey.currentContext?.findRenderObject() as RenderBox?;
      if (actionBox == null || stackBox == null || !actionBox.hasSize) return;

      final topLeft = actionBox.localToGlobal(
        Offset.zero,
        ancestor: stackBox,
      );
      final center = topLeft + actionBox.size.center(Offset.zero);
      if (_widgetActionCenter != center) {
        setState(() => _widgetActionCenter = center);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // loading the media
  // ---------------------------------------------------------------------------

  void _loadInitialImage() {
    if (widget.screenshotImage != null) {
      loadImage(widget.screenshotImage!);
      return;
    }
    if (mediaService.tempPath.existsSync()) {
      loadImage(ScreenshotImageHelper(file: mediaService.tempPath));
    } else if (mediaService.originalPath.existsSync()) {
      loadImage(ScreenshotImageHelper(file: mediaService.originalPath));
    }
  }

  void _initVideoController() {
    setState(() {
      sendingOrLoadingImage = false;
      loadingImage = false;
    });
    videoController = VideoPlayerController.file(
      mediaService.originalPath,
      videoPlayerOptions: VideoPlayerOptions(),
    );
    videoController?.setLooping(true);
    videoController
        ?.initialize()
        .then((_) async {
          _loadStoredTrim();
          if (_trimStart > Duration.zero) {
            await videoController!.seekTo(_trimStart);
          }
          await videoController!.play();
          setState(() {});
        })
        // ignore: argument_type_not_assignable_to_error_handler
        .catchError(Log.error);
  }

  /// Restores a cut made before the editor was closed and reopened on the same
  /// draft. Bounds that no longer fit the recording are dropped rather than
  /// clamped, because a mismatch means they belong to a different clip.
  void _loadStoredTrim() {
    final duration = videoController?.value.duration ?? Duration.zero;
    final start = mediaService.trimStart;
    final end = mediaService.trimEnd;
    if (start != null && start > Duration.zero && start < duration) {
      _trimStart = start;
    }
    if (end != null && end > _trimStart && end < duration) {
      _trimEnd = end;
    }
  }

  /// Where the clip ends, with "not cut" resolved to the end of the recording.
  Duration get _effectiveTrimEnd =>
      _trimEnd ?? videoController?.value.duration ?? Duration.zero;

  /// Stores the cut once the finger lifts. An end on the last frame is stored
  /// as "not cut" so a clip nobody shortened never carries a bound that a
  /// re-encode could round past its own duration.
  Future<void> _persistTrim(Duration start, Duration end) async {
    final duration = videoController?.value.duration ?? Duration.zero;
    await mediaService.setTrim(
      start > Duration.zero ? start : null,
      end < duration ? end : null,
    );
  }

  Future<void> loadImage(ScreenshotImageHelper screenshotImage) async {
    if (screenshotImage.image == null &&
        screenshotImage.imageBytes == null &&
        screenshotImage.imageBytesFuture != null) {
      // this ensures that the imageBytes are defined
      await mediaWriter.storeAsDraft(screenshotImage);
    } else {
      // store this image so it can be used as a draft in case the app is restarted
      unawaited(mediaWriter.storeAsDraft(screenshotImage));
    }

    if (screenshotImage.image == null) {
      final imageBytes = await screenshotImage.getBytes();
      if (imageBytes != null) {
        screenshotImage.image = await decodeImageFromList(imageBytes);
      }
    }
    if (screenshotImage.image == null) {
      Log.error('Could not load screenshotImage.image');
      return;
    }

    currentImage.load(screenshotImage);

    if (isDisposed) return;

    if (!context.mounted) return;

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (context.mounted) {
        await widget.mainCameraController?.closeCamera();
      }
    });

    setState(() {
      layerStack.insertBackgroundLayer(currentImage);
    });

    _waitUntilBackgroundIsPainted();
  }

  /// The user may only send the image once it is fully painted, otherwise the
  /// screenshot taken for the export would be transparent.
  void _waitUntilBackgroundIsPainted() {
    _imageLoadingTimer = Timer.periodic(const Duration(milliseconds: 10), (
      timer,
    ) {
      if (!layerStack.isBackgroundLoaded) return;
      timer.cancel();
      Future.delayed(const Duration(milliseconds: 50), () {
        if (context.mounted) {
          setState(() {
            sendingOrLoadingImage = false;
            loadingImage = false;
          });
        }
      });
    });
  }

  // ---------------------------------------------------------------------------
  // toolbar actions
  // ---------------------------------------------------------------------------

  Future<void> _toggleAudio() async {
    await mediaService.toggleRemoveAudio();
    if (mediaService.removeAudio) {
      await videoController?.setVolume(0);
    } else {
      await videoController?.setVolume(100);
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleRequiresAuth() async {
    await mediaService.setRequiresAuth(!media.requiresAuthentication);
    selectedGroupIds = HashSet();
    if (mounted) setState(() {});
  }

  Future<void> _setSendToWidget(bool enabled) async {
    if (_updatingWidgetMode || (enabled && !_widgetRecipientAvailable)) return;

    if (widget.sendToGroup == null) {
      selectedGroupIds.clear();
    }

    if (enabled) {
      _displayLimitBeforeWidget = media.displayLimitInMilliseconds;
      _requiresAuthBeforeWidget = media.requiresAuthentication;
      _previousMediaSettingsCaptured = true;
    }

    setState(() {
      _sendToWidget = enabled;
      _updatingWidgetMode = true;
    });

    try {
      if (enabled) {
        if (media.displayLimitInMilliseconds != null) {
          await mediaService.setDisplayLimit(null);
        }
        if (media.requiresAuthentication) {
          await mediaService.setRequiresAuth(false);
        }
      } else if (_previousMediaSettingsCaptured) {
        if (media.displayLimitInMilliseconds != _displayLimitBeforeWidget) {
          await mediaService.setDisplayLimit(_displayLimitBeforeWidget);
        }
        if (media.requiresAuthentication != _requiresAuthBeforeWidget) {
          await mediaService.setRequiresAuth(_requiresAuthBeforeWidget);
        }
        _previousMediaSettingsCaptured = false;
      }
    } finally {
      if (mounted) {
        setState(() => _updatingWidgetMode = false);
        if (_sendToWidget && !_widgetRecipientAvailable) {
          unawaited(_setSendToWidget(false));
        }
      }
    }
  }

  Future<void> _editDisplayTime() async {
    await showDisplayTimePicker(
      context,
      mediaService: mediaService,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _onClosePressed() async {
    if (!layerStack.hasUserAddedLayers) {
      Navigator.pop(context, false);
      return;
    }
    await askToCloseThenClose();
  }

  Future<void> askToCloseThenClose() async {
    final shouldPop = await askToDiscardMedia(context);
    if (mounted && shouldPop) {
      Navigator.pop(context);
    }
  }

  // ---------------------------------------------------------------------------
  // sending
  // ---------------------------------------------------------------------------

  void updateSelectedGroupIds(String groupId, bool checked) {
    if (checked) {
      if (media.requiresAuthentication) {
        selectedGroupIds.clear();
      }
      selectedGroupIds.add(groupId);
    } else {
      selectedGroupIds.remove(groupId);
    }
    setState(() {});
  }

  Future<ScreenshotImageHelper?> storeImageAsOriginal() =>
      mediaWriter.storeImageAsOriginal(pixelRatio);

  AdditionalMessageData? getAdditionalData() {
    if (widget.previewLink == null) return null;
    return AdditionalMessageData(
      type: AdditionalMessageData_Type.LINK,
      link: widget.previewLink!.url.toString(),
    );
  }

  Future<void> pushShareImageView() async {
    final mediaStoreFuture = storeImageAsOriginal();

    await videoController?.pause();
    if (isDisposed || !mounted) return;
    final wasSend = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ShareImageView(
          selectedGroupIds: selectedGroupIds,
          updateSelectedGroupIds: updateSelectedGroupIds,
          mediaStoreFuture: mediaStoreFuture,
          mediaFileService: mediaService,
          additionalData: getAdditionalData(),
          sendToWidget: _sendToWidget,
        ),
      ),
    );
    if (wasSend != null && wasSend && mounted) {
      widget.mainCameraController?.onImageSend();
      Navigator.pop(context, true);
    } else {
      await videoController?.play();
    }
  }

  Future<void> sendImageToSinglePerson() async {
    if (sendingOrLoadingImage) return;
    setState(() {
      sendingOrLoadingImage = true;
    });

    if (!context.mounted) return;

    widget.mainCameraController?.onImageSend();

    // must be awaited so the widget for the screenshot is not already disposed when sending..
    await storeImageAsOriginal();

    // Insert media file into the messages database and start uploading process in the background
    await RustApi.sendMediaToGroups(
      mediaId: mediaService.mediaFile.mediaId,
      groupIds: [widget.sendToGroup!.groupId],
      additionalMessageData: getAdditionalData()?.writeToBuffer(),
      widgetOnly: _sendToWidget,
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  // ---------------------------------------------------------------------------
  // layout
  // ---------------------------------------------------------------------------

  /// The cutter only makes sense once the player knows how long the recording
  /// is, and only for a video that is still being edited.
  bool get _canTrim =>
      media.type == MediaType.video &&
      videoController != null &&
      videoController!.value.isInitialized &&
      videoController!.value.duration > Duration.zero;

  /// Tapping anywhere on the media adds a text layer at that position.
  void _onCanvasTap() {
    layerStack.addTextLayer(offset: Offset(0, tabDownPosition));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    pixelRatio = MediaQuery.of(context).devicePixelRatio;
    if (_showWidgetExplainer) _scheduleWidgetActionMeasurement();

    final double widgetExplainerWidth = math.min(
      340,
      MediaQuery.sizeOf(context).width - 82,
    );
    final widgetActionCenter = _widgetActionCenter;

    return PopScope<bool?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await askToCloseThenClose();
      },
      child: Scaffold(
        backgroundColor: widget.sharedFromGallery
            ? null
            : Colors.white.withAlpha(0),
        resizeToAvoidBottomInset: false,
        body: Stack(
          key: _editorStackKey,
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTapDown: (details) {
                if (details.globalPosition.dy > 60) {
                  tabDownPosition = details.globalPosition.dy - 60;
                } else {
                  tabDownPosition = details.globalPosition.dy;
                }
              },
              onTap: _onCanvasTap,
              child: MediaViewSizingHelper.cameraEditor(
                bottomNavigation: EditorBottomBar(
                  mediaService: mediaService,
                  sendToGroup: widget.sendToGroup,
                  isLoadingImage: loadingImage,
                  isSending: sendingOrLoadingImage || _updatingWidgetMode,
                  storeImageAsOriginal: storeImageAsOriginal,
                  onAddMoreRecipients: pushShareImageView,
                  onSend: () async {
                    if (widget.sendToGroup == null) {
                      return pushShareImageView();
                    }
                    await sendImageToSinglePerson();
                  },
                ),
                child: EditorCanvas(
                  layerStack: layerStack,
                  screenshotController: screenshotController,
                  image: currentImage,
                  pixelRatio: pixelRatio,
                  videoController: videoController,
                  onLayersUpdated: () => setState(() {}),
                  bottomOverlay: (_canTrim && _trimmerVisible)
                      ? VideoTrimmer(
                          controller: videoController!,
                          start: _trimStart,
                          end: _effectiveTrimEnd,
                          onChanged: (start, end) {
                            setState(() {
                              _trimStart = start;
                              _trimEnd = end;
                            });
                          },
                          onChangeEnd: _persistTrim,
                        )
                      : null,
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 5,
              right: 0,
              child: SafeArea(
                child: EditorTopToolbar(
                  layerStack: layerStack,
                  onClose: _onClosePressed,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
            if (_showWidgetExplainer && widgetActionCenter != null)
              Positioned(
                left: math.max(
                  12,
                  widgetActionCenter.dx + 24 - widgetExplainerWidth,
                ),
                top: widgetActionCenter.dy,
                width: widgetExplainerWidth,
                child: FractionalTranslation(
                  translation: const Offset(0, -0.5),
                  child: WidgetShareExplainer(
                    onDismiss: _dismissWidgetExplainer,
                  ),
                ),
              ),
            Positioned(
              right: 6,
              top: 100,
              child: Container(
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SafeArea(
                  child: EditorSideToolbar(
                    layerStack: layerStack,
                    mediaService: mediaService,
                    onChanged: () => setState(() {}),
                    onEditDisplayTime: _editDisplayTime,
                    onToggleAudio: _toggleAudio,
                    onToggleRequiresAuth: _toggleRequiresAuth,
                    sendToWidget: _sendToWidget,
                    showWidgetOption: _widgetRecipientAvailable,
                    highlightWidgetOption: _showWidgetExplainer,
                    isUpdatingWidgetMode: _updatingWidgetMode,
                    widgetActionKey: _widgetActionKey,
                    onToggleSendToWidget: () =>
                        _setSendToWidget(!_sendToWidget),
                    canTrim: _canTrim,
                    trimmerVisible: _trimmerVisible,
                    onToggleTrimmer: () =>
                        setState(() => _trimmerVisible = !_trimmerVisible),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
