import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart'
    show AdditionalMessageData, WebxdcOrigin;
import 'package:twonly/src/services/webxdc/webxdc.service.dart';
import 'package:twonly/src/services/webxdc/webxdc_host.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/better_text.element.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_text_entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/friendly_message_time.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/webxdc_app_icon.comp.dart';
import 'package:twonly/src/visual/views/webxdc/webxdc_app.view.dart';

/// A message that came out of a webxdc app, shown with the app it came from.
///
/// Two things end up here: text the user handed to a chat from inside an app,
/// and an announcement an app made in the chat it runs in ("a new game
/// started", "it is your turn"). Either way the words were written by
/// third-party code rather than by the person the bubble belongs to, which is
/// what the header says.
///
/// The app may live in a different chat than the one this was sent to, so the
/// header is only tappable when this device actually has that instance.
class ChatWebxdcMessageEntry extends StatefulWidget {
  const ChatWebxdcMessageEntry({
    required this.message,
    required this.borderRadius,
    required this.info,
    super.key,
  });

  final Message message;
  final BorderRadius borderRadius;
  final BubbleInfo info;

  @override
  State<ChatWebxdcMessageEntry> createState() => _ChatWebxdcMessageEntryState();
}

class _ChatWebxdcMessageEntryState extends State<ChatWebxdcMessageEntry> {
  /// Resolved once and held, so a rebuild -- which any new message in the chat
  /// causes -- does not blank the header out and decode the icon again.
  WebxdcOrigin? _origin;
  WebxdcApp? _app;
  WebxdcInstance? _instance;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    unawaited(_resolve());
  }

  @override
  void didUpdateWidget(ChatWebxdcMessageEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.messageId != widget.message.messageId) {
      _origin = null;
      _app = null;
      _instance = null;
      _resolved = false;
      unawaited(_resolve());
    }
  }

  /// The header as it was the last time this message was on screen, so a card
  /// scrolled back into view does not blank out and decode the icon again while
  /// [_resolve] runs.
  void _seed(WebxdcOrigin origin) {
    _app = WebxdcService.cachedApp(origin.appId, origin.version.toInt());
    _instance = WebxdcService.cachedInstance(origin.instanceId);
  }

  Future<void> _resolve() async {
    final data = widget.message.additionalMessageData;
    WebxdcOrigin? origin;
    if (data != null) {
      try {
        final decoded = AdditionalMessageData.fromBuffer(data);
        if (decoded.hasWebxdcOrigin()) origin = decoded.webxdcOrigin;
      } catch (_) {
        origin = null;
      }
    }
    if (origin == null) {
      if (mounted) setState(() => _resolved = true);
      return;
    }
    // Assigned rather than set: both callers are followed by a build, and this
    // runs synchronously inside `initState`, where `setState` is not allowed.
    _origin = origin;
    _seed(origin);

    final app = await WebxdcService.appNamed(
      origin.appId,
      origin.version.toInt(),
    );
    final instance = await WebxdcService.instanceRow(origin.instanceId);
    if (!mounted) return;
    setState(() {
      _origin = origin;
      _app = app;
      _instance = instance;
      _resolved = true;
    });
  }

  Future<void> _openApp() async {
    final instance = _instance;
    if (instance == null) return;
    final launch = await WebxdcHost.prepare(
      instance.instanceId,
      readerLanguages(context),
    );
    if (launch.failure != null || !mounted) return;
    await context.navPush(WebxdcAppView(launch: launch));
  }

  @override
  Widget build(BuildContext context) {
    final origin = _origin;
    if (origin == null) {
      // Either the marker is missing or it did not decode. Nothing is lost by
      // showing the message the way any other text message is shown.
      if (!_resolved) return const SizedBox.shrink();
      return ChatTextEntry(
        message: widget.message,
        borderRadius: widget.borderRadius,
        info: widget.info,
      );
    }

    final app = _app;
    final name = app == null
        ? origin.appId
        : WebxdcService.localizedName(app, readerLanguages(context));

    return IntrinsicWidth(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
          minWidth: widget.info.minWidth,
        ),
        padding: widget.info.padding,
        decoration: BoxDecoration(
          color: widget.info.color,
          borderRadius: widget.borderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _instance == null ? null : _openApp,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WebxdcAppIcon(
                    app: _app,
                    size: 16,
                    radius: 4,
                    color: widget.info.textColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.info.textColor,
                      ),
                    ),
                  ),
                  if (_instance != null) ...[
                    const SizedBox(width: 4),
                    FaIcon(
                      FontAwesomeIcons.angleRight,
                      size: 10,
                      color: widget.info.textColor,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: BetterText(
                    text: widget.info.text,
                    textColor: widget.info.textColor,
                  ),
                ),
                FriendlyMessageTime(message: widget.message),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
