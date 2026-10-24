import 'dart:async';
import 'dart:collection';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mutex/mutex.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/bridge/database/messages.dart' as rust_messages;
import 'package:twonly/core/bridge/database/stories.dart' as rust_stories;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart'
    as db_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/database/app/messages/table.dart' as db_messages;
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/services/mediafiles/media_download_policy.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/native.notifications.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/mention_editing_controller.dart';
import 'package:twonly/src/visual/helpers/media_view_sizing.helper.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';
import 'package:twonly/src/visual/views/camera/camera_send_to.view.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/additional_message_content.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/keyboard_dismiss_observer.comp.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/media_content_renderer.comp.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/media_viewer_bottom_navigation.comp.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/media_viewer_message_input.comp.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/own_story_bottom_bar.comp.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/reaction_buttons.comp.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/story_expiry_timer.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/twonly_present_overlay.comp.dart';
import 'package:video_player/video_player.dart';

/// What a story viewer plays: one contact's active story, or the user's own.
class StorySource {
  const StorySource.contact(int this.contactId, {this.initialMediaId})
    : own = false;
  const StorySource.own({this.initialMediaId}) : contactId = null, own = true;

  final int? contactId;
  final bool own;

  /// The item to start at. Without one a contact's story starts at the first
  /// item not seen yet, and the user's own story at its oldest item.
  final String? initialMediaId;
}

class MediaViewerView extends StatefulWidget {
  const MediaViewerView(Group this.group, {super.key, this.initialMessage})
    : story = null;

  /// Plays a story instead of a chat's unopened media. Items replay until
  /// they expire, so nothing here is removed after it was shown.
  const MediaViewerView.story(StorySource this.story, {super.key})
    : group = null,
      initialMessage = null;

  final Group? group;

  final StoredMessage? initialMessage;
  final StorySource? story;
  @override
  State<MediaViewerView> createState() => _MediaViewerViewState();
}

class _MediaViewerViewState extends State<MediaViewerView> {
  Timer? nextMediaTimer;
  Timer? progressTimer;
  final StoryExpiryTimer _storyExpiryTimer = StoryExpiryTimer();

  bool showShortReactions = false;
  double mediaViewerDistanceFromBottom = 0;

  // current image related
  VideoPlayerController? videoController;

  VoidCallback? _videoListener;

  MediaFileService? currentMedia;
  StoredMessage? currentMessage;

  DateTime? canBeSeenUntil;
  final ValueNotifier<double> progress = ValueNotifier(0);
  bool showSendTextMessageInput = false;
  DateTime? _lastTimeInputClosed;
  final GlobalKey mediaWidgetKey = GlobalKey();

  bool imageSaved = false;
  bool imageSaving = false;
  bool displayTwonlyPresent = false;
  bool _showDownloadingLoader = false;
  late String _currentMediaSender;
  final emojiKey = GlobalKey<EmojiFloatWidgetState>();

  StreamSubscription<MediaFile?>? downloadStateListener;

  List<StoredMessage> allMediaFiles = [];
  StreamSubscription<List<StoredMessage>>? _subscription;
  final textMessageController = MentionEditingController();
  final _textMessageFocus = FocusNode();

  final HashSet<String> _alreadyOpenedMediaIds = HashSet();

  bool _isTransitioning = false;

  /// The chat replies go to. For a contact's story it is the direct chat the
  /// story rows are filed under, looked up once the story is loaded.
  Group? _group;

  bool get _isStory => widget.story != null;
  bool get _isOwnStory => widget.story?.own ?? false;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _currentMediaSender = widget.group?.groupName ?? '';

    if (_isStory) {
      unawaited(_loadStory());
      return;
    }

    if (widget.initialMessage != null &&
        !widget.initialMessage!.isWidgetMedia) {
      allMediaFiles = [widget.initialMessage!];
    }

    listenForUnopenedMedia(true);
  }

  @override
  void dispose() {
    nextMediaTimer?.cancel();
    progressTimer?.cancel();
    _storyExpiryTimer.cancel();
    _subscription?.cancel();
    downloadStateListener?.cancel();
    progress.dispose();

    ScreenProtector.preventScreenshotOff();

    _disposeVideoController();

    // Persist draft message on close
    final draftText = textMessageController.messageText;
    if (!_isStory) {
      unawaited(
        rust_groups.updateGroup(
          id: widget.group!.groupId,
          patch: GroupPatch(
            draftMessage: NullableText(
              value: draftText.isEmpty ? null : draftText,
            ),
          ),
          transaction: currentDatabaseSession(),
        ),
      );
    }
    textMessageController.dispose();
    _textMessageFocus.dispose();

    super.dispose();
  }

  void _disposeVideoController() {
    final listener = _videoListener;
    final controller = videoController;
    _videoListener = null;
    videoController = null;
    if (listener != null) {
      controller?.removeListener(listener);
    }
    controller?.dispose();
  }

  final Mutex _messageUpdateLock = Mutex();

  /// A story is a fixed playlist: its items are all there when it is opened,
  /// and new ones show up the next time it is.
  Future<void> _loadStory() async {
    final story = widget.story!;
    final now = clock.now();
    var playlist = <StoredMessage>[];
    var start = 0;
    if (story.own) {
      final items = await (() {
        final cutoff =
            clock.now().subtract(storyLifetime).millisecondsSinceEpoch ~/ 1000;
        return watchRustDatabase(
          (control) => rust_stories
              .watchOwnStories(cutoff: cutoff, control: control)
              .map(ownStoryItems),
        );
      })().first;
      for (final item in items.where((item) => item.isActiveAt(now))) {
        final rows = await rust_messages.listMessages(
          input: db_messages.MessageQuery(
            filter: db_messages.MessageFilter.mediaIds,
            ids: [item.mediaFile.mediaId].toList(),
            nowMs: clock.now().millisecondsSinceEpoch,
          ),
          transaction: currentDatabaseSession(),
        );
        final row = rows
            .where((row) => row.isStory && row.senderId == null)
            .firstOrNull;
        if (row != null) playlist.add(row);
      }
      if (mounted) _currentMediaSender = context.lang.storyMine;
    } else {
      final contactId = story.contactId!;
      playlist =
          receivedStoryItems(
                await rust_stories.getReceivedStories(
                  contact: contactId,
                  cutoff:
                      clock
                          .now()
                          .subtract(storyLifetime)
                          .millisecondsSinceEpoch ~/
                      1000,
                  transaction: currentDatabaseSession(),
                ),
              )
              .where((item) => item.isActiveAt(now))
              .map((item) => item.message)
              .toList();
      start = playlist.indexWhere((message) => message.openedAt == null);
      if (start < 0) start = 0;
      final contact = await rust_contacts.getContact(
        id: contactId,
        transaction: currentDatabaseSession(),
      );
      if (contact != null) _currentMediaSender = getContactDisplayName(contact);
      if (playlist.isNotEmpty) {
        _group = await rust_groups.getGroup(
          id: playlist.first.groupId,
          transaction: currentDatabaseSession(),
        );
      }
    }
    final initial = story.initialMediaId;
    if (initial != null) {
      final index = playlist.indexWhere((m) => m.mediaId == initial);
      if (index >= 0) start = index;
    }
    if (!mounted) return;
    setState(() {
      allMediaFiles = playlist.isEmpty ? [] : playlist.sublist(start);
    });
    await loadAndDownloadCurrentMedia();
  }

  Future<void> listenForUnopenedMedia(bool firstRun) async {
    _subscription =
        watchRustDatabase(
          (control) => rust_messages.watchMessages(
            input: db_messages.MessageQuery(
              filter: db_messages.MessageFilter.mediaUnopened,
              groupId: widget.group!.groupId,
              nowMs: clock.now().millisecondsSinceEpoch,
            ),
            control: control,
          ),
        ).listen((
          messages,
        ) async {
          await _messageUpdateLock.protect(() async {
            for (final msg in messages) {
              if (msg.isWidgetMedia) {
                continue;
              }
              if (_alreadyOpenedMediaIds.contains(msg.mediaId)) {
                continue;
              }
              if (msg.mediaId == null) {
                continue;
              }

              if (msg.mediaId == currentMedia?.mediaFile.mediaId) {
                // The update of the current Media in case of a download is done in loadAndDownloadCurrentMedia
                continue;
              }

              /// If the messages was already there just replace it and go to the next...

              final index = allMediaFiles.indexWhere(
                (m) => m.messageId == msg.messageId,
              );

              if (index >= 1) {
                allMediaFiles[index] = msg;
              } else if (index == -1) {
                // If the message does not exist, add it
                allMediaFiles.add(msg);
              }
            }
            if (allMediaFiles.length > 1) {
              if (widget.initialMessage == null &&
                  currentMedia == null &&
                  !_showDownloadingLoader) {
                allMediaFiles.sort(
                  (a, b) => a.createdAt.compareTo(b.createdAt),
                );
              } else {
                final upcoming = allMediaFiles.sublist(1)
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                allMediaFiles = [allMediaFiles.first, ...upcoming];
              }
            }
            if (mounted) setState(() {});
            if (firstRun) {
              firstRun = false;
              await loadAndDownloadCurrentMedia();
            }
          });
        });
  }

  Future<void> advanceToNextMediaOrExit() async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      /// Remove the current media file in case it is not set to unlimited.
      /// A story replays until it expires, whatever the file says.
      if (currentMedia != null && !_isStory) {
        if (!imageSaved &&
            currentMedia!.mediaFile.displayLimitInMilliseconds != null) {
          await currentMedia!.fullMediaRemoval();
        }
      }

      _disposeVideoController();

      if (!mounted) return;

      nextMediaTimer?.cancel();
      progressTimer?.cancel();
      _storyExpiryTimer.cancel();

      if (allMediaFiles.isEmpty && _isStory) {
        if (mounted) Navigator.pop(context);
      } else if (allMediaFiles.isEmpty) {
        final group = await rust_groups.getGroup(
          id: widget.group!.groupId,
          transaction: currentDatabaseSession(),
        );
        if (mounted) {
          if (group != null &&
              group.draftMessage != null &&
              group.draftMessage != '') {
            context.replace(
              Routes.chatsMessages(group.groupId),
              extra: group,
            );
          } else {
            Navigator.pop(context);
          }
        }
      } else {
        await loadAndDownloadCurrentMedia();
      }
    } finally {
      if (mounted) _isTransitioning = false;
    }
  }

  Future<void> loadAndDownloadCurrentMedia({bool showTwonly = false}) async {
    if (!mounted || !context.mounted) return;
    if (_isStory) {
      final now = clock.now();
      while (allMediaFiles.isNotEmpty &&
          !allMediaFiles.first.createdAt.add(storyLifetime).isAfter(now)) {
        allMediaFiles.removeAt(0);
      }
      if (allMediaFiles.isEmpty) {
        Navigator.pop(context);
        return;
      }
      _storyExpiryTimer.schedule(
        postedAt: allMediaFiles.first.createdAt,
        now: now,
        onExpired: () {
          if (mounted) unawaited(advanceToNextMediaOrExit());
        },
      );
    }
    if (allMediaFiles.isEmpty || allMediaFiles.first.mediaId == null) {
      return advanceToNextMediaOrExit();
    }

    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (e) {
      Log.error(e);
    }

    if (!mounted) return;

    setState(() {
      videoController = null;
      currentMedia = null;
      currentMessage = null;
      canBeSeenUntil = null;
      imageSaving = false;
      imageSaved = false;
      progress.value = 0;
      showSendTextMessageInput = false;
    });

    final stream = watchRustDatabase(
      (control) => rust_mediafiles
          .watchMediaFiles(
            input: db_mediafiles.MediaQuery(
              filter: db_mediafiles.MediaFilter.ids,
              ids: [allMediaFiles.first.mediaId!].toList(),
            ),
            control: control,
          )
          .map(orderedMediaFiles),
    ).map((rows) => rows.isEmpty ? null : rows.single);

    var downloadTriggered = false;

    await downloadStateListener?.cancel();
    downloadStateListener = stream.listen((updated) async {
      if (updated == null) {
        // Media file record no longer exists — skip to next or exit rather
        // than leaving the screen permanently black with no content/loader.
        await downloadStateListener?.cancel();
        await advanceToNextMediaOrExit();
        return;
      }
      // The user's own story plays from the file they sent; there is
      // nothing to download.
      if (!_isOwnStory && updated.downloadState != DownloadState.ready) {
        setState(() {
          _showDownloadingLoader = true;
        });
        if (!downloadTriggered) {
          downloadTriggered = true;
          final mediaFile = await rust_mediafiles.getMediaFile(
            id: allMediaFiles.first.mediaId!,
            transaction: currentDatabaseSession(),
          );
          if (mediaFile == null) {
            // DB record gone — skip to next or exit.
            await downloadStateListener?.cancel();
            await advanceToNextMediaOrExit();
            return;
          }
          await startDownloadMedia(mediaFile, true);
          unawaited(tryDownloadAllMediaFiles(force: true));
        }
        return;
      }

      await downloadStateListener?.cancel();
      try {
        await initializeAndDisplayCurrentMedia(showTwonly);
      } catch (e, st) {
        Log.error('initializeAndDisplayCurrentMedia failed: $e\n$st');
        await advanceToNextMediaOrExit();
      }
      // start downloading all the other possible missing media files.
    });
  }

  Future<void> initializeAndDisplayCurrentMedia(bool showTwonly) async {
    if (allMediaFiles.isEmpty) return;
    setState(() {
      _showDownloadingLoader = false;
    });
    final currentMediaLocal = await MediaFileService.fromMediaId(
      allMediaFiles.first.mediaId!,
    );
    if (currentMediaLocal == null || !mounted) return;

    if (currentMediaLocal.mediaFile.requiresAuthentication) {
      if (!showTwonly) {
        setState(() {
          displayTwonlyPresent = true;
        });
        return;
      }

      final isAuth = await authenticateUser(
        context.lang.mediaViewerAuthReason,
        force: false,
      );
      if (!mounted) return;

      if (!isAuth) {
        await advanceToNextMediaOrExit();
        if (mounted) {
          setState(() {
            displayTwonlyPresent = false;
          });
        }
        return;
      }
    }

    _alreadyOpenedMediaIds.add(allMediaFiles.first.mediaId!);
    currentMessage = allMediaFiles.removeAt(0);

    setState(() {
      displayTwonlyPresent = false;
    });

    await _updateSenderInfo();
    if (!mounted) return;

    await _notifyMessageOpened(currentMediaLocal);
    if (!mounted) return;

    if (!currentMediaLocal.tempPath.existsSync()) {
      Log.warn(
        'Temp media file not found for media ID: ${currentMediaLocal.mediaFile.mediaId}',
      );
      if (!_isOwnStory) {
        await RustApi.requestMediaReupload(
          mediaId: currentMediaLocal.mediaFile.mediaId,
        );
      }
      return advanceToNextMediaOrExit();
    }

    // The server can now delete the encrypted bytes, as the user has successfully opened it.
    final downloadToken = currentMediaLocal.mediaFile.downloadToken;
    if (downloadToken != null) {
      Log.info(
        'Calling downloadDone for media ID: ${currentMediaLocal.mediaFile.mediaId}',
      );
      unawaitedRustCall(
        RustApi.downloadDone(token: downloadToken),
        'downloadDone',
      );
    }

    if (currentMediaLocal.mediaFile.type == MediaType.video) {
      await _setupVideoPlayer(currentMediaLocal);
    } else {
      _setupImageTimer(currentMediaLocal);
    }

    if (mounted) {
      setState(() {
        currentMedia = currentMediaLocal;
      });
    }
  }

  Future<void> _updateSenderInfo() async {
    final group = widget.group;
    if (currentMessage == null || group == null || group.isDirectChat) return;
    final sender = await rust_contacts.getContact(
      id: currentMessage!.senderId!,
      transaction: currentDatabaseSession(),
    );
    if (mounted && sender != null) {
      _currentMediaSender =
          '${getContactDisplayName(sender)} (${group.groupName})';
    }
  }

  Future<void> _notifyMessageOpened(MediaFileService mediaLocal) async {
    if (currentMessage == null || _isOwnStory) return;
    // A story item is reported the first time only; replays are not news.
    if (_isStory && currentMessage!.openedAt != null) return;
    var markAsOpenMessageIDs = [currentMessage!.messageId];

    if (!_isStory &&
        userService.currentUser.automaticallyMarkEqualMediaFilesAsOpened &&
        mediaLocal.mediaFile.storedFileHash != null) {
      final messageIds = await rust_mediafiles.mediaMessageIdsByHash(
        hash: mediaLocal.mediaFile.storedFileHash!,
        sender: currentMessage!.senderId!,
        transaction: currentDatabaseSession(),
      );

      if (!messageIds.contains(currentMessage!.messageId)) {
        Log.error(
          'Original message ID was not returned from `getMessageIdsByMediaHash`.',
        );
        messageIds.add(currentMessage!.messageId);
      }

      markAsOpenMessageIDs = messageIds;
    }

    await NativeNotificationService.cancelNotifications(markAsOpenMessageIDs);
    try {
      await RustApi.notifyMessagesOpened(
        contactId: currentMessage!.senderId!,
        messageIds: markAsOpenMessageIDs,
      );
    } finally {
      await NativeNotificationService.cancelNotifications(markAsOpenMessageIDs);
    }
  }

  Future<void> _setupVideoPlayer(MediaFileService mediaLocal) async {
    final controller = VideoPlayerController.file(
      mediaLocal.tempPath,
      videoPlayerOptions: VideoPlayerOptions(),
    );

    await controller.setLooping(
      _isStory || mediaLocal.mediaFile.displayLimitInMilliseconds == null,
    );

    if (!mounted) {
      await controller.dispose();
      return;
    }

    await controller
        .initialize()
        .then((_) {
          if (!mounted || videoController != null) {
            controller.dispose();
            return;
          }

          void listener() {
            if (!mounted) return;
            final ctrl = videoController;
            if (ctrl == null) return;

            final duration = ctrl.value.duration.inSeconds;
            if (duration > 0) {
              progress.value = 1 - ctrl.value.position.inSeconds / duration;
            }

            if (!_isStory &&
                mediaLocal.mediaFile.displayLimitInMilliseconds != null) {
              if (ctrl.value.position == ctrl.value.duration) {
                advanceToNextMediaOrExit();
              }
            }
          }

          _videoListener = listener;
          videoController = controller;
          controller
            ..addListener(listener)
            ..play();
        })
        .catchError((Object err, StackTrace st) {
          Log.error(
            'Video player initialization error',
            error: err,
            stackTrace: st,
          );
          return null;
        });
  }

  void _setupImageTimer(MediaFileService mediaLocal) {
    // A story image stays until the viewer moves on.
    if (!_isStory && mediaLocal.mediaFile.displayLimitInMilliseconds != null) {
      canBeSeenUntil = clock.now().add(
        Duration(
          milliseconds: mediaLocal.mediaFile.displayLimitInMilliseconds!,
        ),
      );
      if (mounted) {
        startProgressTimer();
      }
    }
  }

  void startProgressTimer() {
    nextMediaTimer?.cancel();
    progressTimer?.cancel();
    if (canBeSeenUntil != null) {
      nextMediaTimer = Timer(canBeSeenUntil!.difference(clock.now()), () {
        if (context.mounted) {
          advanceToNextMediaOrExit();
        }
      });
      progressTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        final mediaFile = currentMedia?.mediaFile;
        if (mediaFile == null) return;
        if (mediaFile.displayLimitInMilliseconds == null ||
            canBeSeenUntil == null) {
          return;
        }
        final difference = canBeSeenUntil!.difference(clock.now());
        // Calculate the progress as a value between 0.0 and 1.0
        progress.value =
            difference.inMilliseconds / (mediaFile.displayLimitInMilliseconds!);
      });
    }
  }

  Future<void> onPressedSaveToGallery() async {
    if (!mounted) return;
    final media = currentMedia;
    final msg = currentMessage;
    if (media == null || msg == null) return;

    setState(() {
      imageSaving = true;
    });
    await media.storeMediaFile();
    await rust_messages.updateMessages(
      id: msg.messageId,
      byMedia: false,
      patch: const MessagePatch(mediaStored: true),
      transaction: currentDatabaseSession(),
    );
    await RustApi.sendEncryptedContentToGroup(
      groupId: msg.groupId,
      content: pb.EncryptedContent(
        mediaUpdate: pb.EncryptedContent_MediaUpdate(
          type: pb.EncryptedContent_MediaUpdate_Type.STORED,
          targetMessageId: msg.messageId,
        ),
      ).writeToBuffer(),
      onlySendIfNoReceiptsAreOpen: false,
    );
    if (!mounted) return;
    setState(() {
      imageSaved = true;
      imageSaving = false;
    });
  }

  void displayShortReactions() {
    final renderBox =
        mediaWidgetKey.currentContext!.findRenderObject() as RenderBox?;
    setState(() {
      showShortReactions = true;
      if (renderBox != null) {
        mediaViewerDistanceFromBottom = renderBox.size.height;
      }
    });
  }

  Widget bottomNavigation() {
    if (_isOwnStory) {
      return OwnStoryBottomBar(
        key: mediaWidgetKey,
        mediaFile: currentMedia?.mediaFile,
        onDeleted: advanceToNextMediaOrExit,
      );
    }
    return MediaViewerBottomNavigationBar(
      key: mediaWidgetKey,
      currentMedia: currentMedia,
      currentMessage: currentMessage,
      imageSaving: imageSaving,
      imageSaved: imageSaved,
      showShortReactions: showShortReactions,
      onSaveToGallery: onPressedSaveToGallery,
      onToggleReactions: () {
        if (!showShortReactions) {
          displayShortReactions();
        } else {
          setState(() {
            showShortReactions = false;
          });
        }
      },
      onMessagePressed: () {
        displayShortReactions();
        setState(() {
          showSendTextMessageInput = true;
        });
      },
      onCameraPressed: () async {
        nextMediaTimer?.cancel();
        progressTimer?.cancel();
        await videoController?.pause();
        if (!mounted) return;
        final group = _group;
        if (group == null) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return CameraSendToView(group);
            },
          ),
        );
        if (mounted &&
            !_isStory &&
            currentMedia!.mediaFile.displayLimitInMilliseconds != null) {
          await advanceToNextMediaOrExit();
        } else {
          await videoController?.play();
        }
      },
    );
  }

  Widget _loader() {
    return Center(
      child: SizedBox(
        height: 60,
        width: 60,
        child: ThreeRotatingDots(
          size: 40,
          color: context.color.primary,
        ),
      ),
    );
  }

  void _sendTextMessage() {
    if (textMessageController.text.isNotEmpty) {
      unawaitedRustCall(
        RustApi.insertAndSendText(
          groupId: currentMessage!.groupId,
          text: textMessageController.messageText,
          quoteMessageId: currentMessage!.messageId,
        ),
        'insertAndSendText',
      );
      textMessageController.clear();
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      showSendTextMessageInput = false;
      showShortReactions = false;
      _lastTimeInputClosed = clock.now();
    });
  }

  void onScreenTapped() {
    if (_lastTimeInputClosed != null &&
        clock.now().difference(_lastTimeInputClosed!) <
            const Duration(milliseconds: 300)) {
      return;
    }
    if (showSendTextMessageInput) {
      setState(() {
        showShortReactions = false;
        showSendTextMessageInput = false;
        _lastTimeInputClosed = clock.now();
      });
      return;
    }
    advanceToNextMediaOrExit();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissObserver(
      showSendTextMessageInput: showSendTextMessageInput,
      onKeyboardDismissed: () {
        setState(() {
          showSendTextMessageInput = false;
          showShortReactions = false;
          _lastTimeInputClosed = clock.now();
        });
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          maintainBottomViewPadding: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_showDownloadingLoader) _loader(),
              if ((currentMedia != null || videoController != null) &&
                  (canBeSeenUntil == null || progress.value >= 0))
                GestureDetector(
                  onTap: onScreenTapped,
                  onDoubleTap: (videoController == null)
                      ? null
                      : onScreenTapped,
                  child: MediaViewSizingHelper(
                    bottomNavigation: bottomNavigation(),
                    requiredHeight: 55,
                    child: MediaContentRenderer(
                      currentMedia: currentMedia,
                      videoController: videoController,
                      loader: _loader(),
                    ),
                  ),
                ),
              if (displayTwonlyPresent)
                TwonlyPresentOverlay(
                  onTap: () => loadAndDownloadCurrentMedia(showTwonly: true),
                ),
              if (currentMedia != null &&
                  currentMedia?.mediaFile.downloadState != DownloadState.ready)
                Positioned.fill(child: _loader()),
              // A story image has no clock to show; a video still shows how far
              // it has played.
              if ((canBeSeenUntil != null || progress.value >= 0) &&
                  !(_isStory && videoController == null))
                Positioned(
                  right: 20,
                  top: 27,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: ValueListenableBuilder<double>(
                          valueListenable: progress,
                          builder: (context, value, child) {
                            return CircularProgressIndicator(
                              value: value,
                              strokeWidth: 2,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              Positioned(
                top: 10,
                left: showSendTextMessageInput ? 0 : null,
                right: showSendTextMessageInput ? 0 : 15,
                child: Text(
                  _currentMediaSender,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: showSendTextMessageInput ? 24 : 14,
                    fontWeight: FontWeight.bold,
                    color: showSendTextMessageInput
                        ? null
                        : context.appColor(AppColor.mediaForegroundMuted),
                    shadows: [
                      Shadow(
                        color: context.appColor(AppColor.mediaScrim),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
              if (showSendTextMessageInput)
                MediaViewerMessageInput(
                  controller: textMessageController,
                  group: _group,
                  focusNode: _textMessageFocus,
                  safeAreaBottomPadding: MediaQuery.viewPaddingOf(
                    context,
                  ).bottom,
                  onSubmitted: (value) => _sendTextMessage(),
                  onSendPressed: _sendTextMessage,
                ),
              if (currentMessage != null)
                AdditionalMessageContent(currentMessage!),
              if (currentMedia != null && !_isOwnStory)
                ReactionButtons(
                  show: showShortReactions,
                  textInputFocused: showSendTextMessageInput,
                  mediaViewerDistanceFromBottom: mediaViewerDistanceFromBottom,
                  groupId: currentMessage!.groupId,
                  messageId: currentMessage!.messageId,
                  // A story row never shows in the chat, so a reaction to it
                  // goes there as a message quoting the story instead.
                  asQuotedText: _isStory,
                  emojiKey: emojiKey,
                  hide: () {
                    setState(() {
                      showShortReactions = false;
                      showSendTextMessageInput = false;
                      _lastTimeInputClosed = clock.now();
                    });
                  },
                ),
              Positioned.fill(
                child: EmojiFloatWidget(key: emojiKey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
