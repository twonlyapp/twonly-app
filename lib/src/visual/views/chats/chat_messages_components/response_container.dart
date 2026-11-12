import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/messages.dart' as rust_messages;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/model/message_enums.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/stickers/sticker.service.dart';
import 'package:twonly/src/services/webxdc/webxdc.service.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/mentions.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/mention_text.dart';
import 'package:twonly/src/visual/views/chats/chat_messages.view.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_vacation.entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/webxdc_app_icon.comp.dart';

class ResponseContainer extends StatelessWidget {
  const ResponseContainer({
    required this.msg,
    required this.group,
    required this.child,
    required this.mediaService,
    required this.borderRadius,
    this.scrollToMessage,
    this.quotedMessage,
    this.quotedMediaFile,
    this.contactsById,
    this.useSharedData = false,
    super.key,
  });

  final StoredMessage msg;
  final Widget? child;
  final Group group;
  final MediaFileService? mediaService;
  final BorderRadius borderRadius;
  final void Function(String)? scrollToMessage;
  final StoredMessage? quotedMessage;
  final MediaFile? quotedMediaFile;
  final Map<int, Contact>? contactsById;
  final bool useSharedData;

  @override
  Widget build(BuildContext context) {
    if (msg.quotesMessageId == null) {
      if (child == null) {
        return Container();
      }
      return child!;
    }
    return GestureDetector(
      onTap: scrollToMessage == null
          ? null
          : () => scrollToMessage!(msg.quotesMessageId!),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        decoration: BoxDecoration(
          color: getMessageColor(context, msg.senderId != null),
          borderRadius: borderRadius,
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.color.surface.withAlpha(150),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: ResponsePreview(
                    group: group,
                    messageId: msg.quotesMessageId,
                    message: quotedMessage,
                    mediaFile: quotedMediaFile,
                    contactsById: contactsById,
                    contact: quotedMessage?.senderId == null
                        ? null
                        : contactsById?[quotedMessage!.senderId],
                    // A quote the loaded page does not hold, such as a story
                    // the chat never lists, is looked up by the preview.
                    useSharedData: useSharedData && quotedMessage != null,
                    showBorder: false,
                    showLeftBorder: false,
                  ),
                ),
              ),
              ?child,
            ],
          ),
        ),
      ),
    );
  }
}

class ResponsePreview extends StatefulWidget {
  const ResponsePreview({
    required this.group,
    required this.showBorder,
    this.message,
    this.messageId,
    this.showLeftBorder = true,
    this.colorUsername = false,
    this.mediaFile,
    this.contact,
    this.contactsById,
    this.useSharedData = false,
    super.key,
  });

  final StoredMessage? message;
  final String? messageId;
  final Group group;
  final bool showBorder;
  final bool showLeftBorder;
  final bool colorUsername;
  final MediaFile? mediaFile;
  final Contact? contact;
  final Map<int, Contact>? contactsById;
  final bool useSharedData;

  @override
  State<ResponsePreview> createState() => _ResponsePreviewState();
}

class _ResponsePreviewState extends State<ResponsePreview> {
  StoredMessage? _message;
  MediaFileService? _mediaService;
  String _username = '';
  Uint8List? _stickerSource;
  Uint8List? _stickerBytes;
  String? _gameAppId;
  WebxdcCardApp? _gameApp;

  Uint8List? get _quotedStickerBytes {
    final source = _message?.additionalMessageData;
    if (!listEquals(_stickerSource, source)) {
      _stickerSource = source;
      final sticker = StickerService.decodeAdditional(source);
      // MemoryImage uses byte identity as its cache key. Keep the same bytes
      // across rebuilds so the preview does not reload or restart animations.
      _stickerBytes = sticker == null ? null : Uint8List.fromList(sticker.webp);
    }
    return _stickerBytes;
  }

  @override
  void initState() {
    super.initState();
    _message = widget.message;
    if (widget.mediaFile != null) {
      _mediaService = MediaFileService(widget.mediaFile!);
    }
    if (widget.contact != null) {
      _username = getContactDisplayName(widget.contact!);
    }
    _seedGame();
    if (!widget.useSharedData &&
        (widget.message == null ||
            (widget.message?.mediaId != null && widget.mediaFile == null) ||
            (widget.message?.senderId != null && widget.contact == null))) {
      initAsync();
    } else if (_isGame && _gameApp == null) {
      // The shared chat data holds messages, not the apps behind game cards.
      _loadGame().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  bool get _isGame => _message?.type == MessageType.webxdcApp.name;

  /// A game card's message holds neither the app nor its name, only the
  /// instance it starts, which is also the message's ID. Whatever the chat
  /// already looked up is shown right away.
  void _seedGame() {
    if (!_isGame) return;
    final instance = WebxdcService.cachedInstance(_message!.messageId);
    if (instance == null) return;
    _gameAppId = instance.appId;
    _gameApp = WebxdcService.cachedApp(instance.appId, instance.version);
  }

  Future<void> _loadGame() async {
    if (!_isGame || _gameApp != null) return;
    final instance = await WebxdcService.instanceRow(_message!.messageId);
    if (instance == null) return;
    _gameAppId = instance.appId;
    _gameApp = await WebxdcService.cardApp(instance.appId, instance.version);
  }

  Future<void> initAsync() async {
    if (_message == null && widget.messageId != null) {
      _message = await rust_messages.getMessage(
        id: widget.messageId!,
        transaction: currentDatabaseSession(),
      );
    }
    if (_message?.mediaId != null && _mediaService == null) {
      _mediaService = await MediaFileService.fromMediaId(_message!.mediaId!);
    }
    if (_message?.senderId != null && _username.isEmpty) {
      final contact = await rust_contacts.getContact(
        id: _message!.senderId!,
        transaction: currentDatabaseSession(),
      );
      if (contact != null) {
        _username = getContactDisplayName(contact);
      }
    }
    _seedGame();
    await _loadGame();
    if (_message == null && mounted) {
      _username = context.lang.quotedMessageWasDeleted;
    }
    if (mounted) setState(() {});
  }

  /// Whether the quoted story can still be shown. Once it expired, or its
  /// sender took it down, only the fact that it was a story remains.
  bool get _storyAlive {
    final message = _message;
    if (message == null || !message.isStory) return false;
    if (message.mediaStored) return true;
    return message.mediaId != null &&
        _mediaService != null &&
        clock.now().isBefore(messageStoryDeadline(message));
  }

  @override
  Widget build(BuildContext context) {
    String? subtitle;
    var color = context.appColor(AppColor.messageText);
    final quotedStickerBytes = _quotedStickerBytes;

    if (_message != null) {
      if (_message!.type == MessageType.text.name) {
        if (quotedStickerBytes != null) {
          subtitle = context.lang.sticker;
        } else if (_message!.content != null) {
          subtitle = _message!.content!;
        }
      }
      if (_message!.type == MessageType.media.name && _mediaService != null) {
        switch (_mediaService!.mediaFile.type) {
          case MediaType.image:
            subtitle = context.lang.image;
          case MediaType.video:
            subtitle = context.lang.video;
          case MediaType.gif:
            subtitle = 'Gif';
          case MediaType.audio:
            subtitle = 'Audio';
        }
      }
      if (_message!.type == MessageType.contacts.name) {
        subtitle = context.lang.contacts;
      }
      if (_message!.type == MessageType.restoreFlameCounter.name) {
        if (_message!.additionalMessageData != null) {
          try {
            final data = AdditionalMessageData.fromBuffer(
              _message!.additionalMessageData!,
            );
            subtitle = context.lang.chatEntryFlameRestored(
              data.restoredFlameCounter.toInt(),
            );
          } catch (e) {
            subtitle = context.lang.replyFlameRestored;
          }
        } else {
          subtitle = context.lang.replyFlameRestored;
        }
      }
      if (_message!.type == MessageType.onVacation.name) {
        subtitle = vacationEntryText(context, _message!) ?? subtitle;
      }
      if (_message!.type == MessageType.askAboutUser.name) {
        subtitle = context.lang.replyAskAFriend;
      }
      if (_isGame && _gameAppId != null) {
        subtitle = _gameApp == null
            ? _gameAppId
            : WebxdcService.localizedName(_gameApp!, readerLanguages(context));
      }

      if (_message!.senderId == null) {
        _username = context.lang.you;
      }

      if (_message!.isStory) {
        subtitle = _storyAlive ? context.lang.story : context.lang.storyExpired;
      }

      color = getMessageColor(context, _message!.senderId != null);
    }

    final hasImage =
        _message != null &&
        (_message!.mediaStored || _storyAlive) &&
        _mediaService != null &&
        _mediaService!.mediaFile.type != MediaType.audio;

    Widget? imageWidget;
    if (hasImage) {
      final isVideo = _mediaService!.mediaFile.type == MediaType.video;
      // A story nobody saved is still in its temporary file.
      final pathToCheck = isVideo
          ? _mediaService!.thumbnailPath
          : _message!.mediaStored
          ? _mediaService!.storedPath
          : _mediaService!.tempPath;
      imageWidget = Container(
        height: 40,
        width: 40,
        margin: const EdgeInsets.only(left: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(
            pathToCheck,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      );
    } else if (_isGame && _gameAppId != null) {
      imageWidget = Container(
        margin: const EdgeInsets.only(left: 8),
        child: WebxdcAppIcon(
          app: _gameApp,
          size: 40,
          radius: 4,
          color: color,
        ),
      );
    } else if (quotedStickerBytes != null) {
      imageWidget = Container(
        height: 40,
        width: 40,
        margin: const EdgeInsets.only(left: 8),
        child: Image.memory(
          quotedStickerBytes,
          fit: BoxFit.contain,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: widget.showLeftBorder ? 8 : 4,
        right: 6,
        top: 4,
        bottom: 4,
      ),
      constraints: BoxConstraints(
        minWidth: 60,
        maxWidth: MediaQuery.sizeOf(context).width * 0.7,
      ),
      decoration: widget.showLeftBorder
          ? BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: color,
                  width: 2.5,
                ),
              ),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.colorUsername ? color : null,
                  ),
                ),
                if (subtitle != null)
                  MentionNames(
                    text: subtitle,
                    contactsById: widget.useSharedData
                        ? widget.contactsById
                        : null,
                    builder: (context, name) => Text(
                      truncateString(resolveMentions(subtitle!, name)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          ?imageWidget,
        ],
      ),
    );
  }
}
