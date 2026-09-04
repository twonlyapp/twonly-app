import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/webxdc/webxdc.service.dart';
import 'package:twonly/src/services/webxdc/webxdc_host.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/friendly_message_time.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/webxdc_app_icon.comp.dart';
import 'package:twonly/src/visual/views/webxdc/webxdc_app.view.dart';

/// The card an app shows in a chat: icon, name, whatever the app last put in
/// its summary or document, and when it arrived. Tapping it starts the app.
///
/// Every string here except the app's own name comes from `webxdc_instances`,
/// where Rust already stripped control characters and bounded the length. This
/// widget renders them as plain text and does nothing else with them: they are
/// written by third-party code and sit next to real messages.
class ChatWebxdcEntry extends StatefulWidget {
  const ChatWebxdcEntry({
    required this.message,
    required this.borderRadius,
    required this.info,
    super.key,
  });

  final Message message;
  final BorderRadiusGeometry borderRadius;
  final BubbleInfo info;

  @override
  State<ChatWebxdcEntry> createState() => _ChatWebxdcEntryState();
}

class _ChatWebxdcEntryState extends State<ChatWebxdcEntry> {
  /// Held across rebuilds rather than created in `build`.
  ///
  /// A stream or future built during `build` is a new one every time the chat
  /// rebuilds -- which any incoming message causes -- and each new one starts
  /// out empty, so the card would blank out and the icon would visibly reload
  /// every time anything else in the chat changed.
  StreamSubscription<WebxdcInstance?>? _subscription;
  WebxdcInstance? _instance;
  WebxdcApp? _app;

  @override
  void initState() {
    super.initState();
    _seed();
    _subscribe();
  }

  @override
  void didUpdateWidget(ChatWebxdcEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.messageId != widget.message.messageId) {
      _seed();
      _subscribe();
    }
  }

  /// What the card looked like the last time this message was on screen.
  ///
  /// Scrolling a card out of view destroys its state, and the query behind it
  /// only answers a frame or two after the card is built again; starting from
  /// nothing would collapse the card and then pop it back in. The stream still
  /// corrects whatever changed in the meantime.
  void _seed() {
    final instance = WebxdcService.cachedInstance(widget.message.messageId);
    _instance = instance;
    _app = instance == null
        ? null
        : WebxdcService.cachedApp(instance.appId, instance.version);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _subscribe() {
    unawaited(_subscription?.cancel());
    _subscription = WebxdcService.watchInstance(
      widget.message.messageId,
    ).listen(_onInstance);
  }

  Future<void> _onInstance(WebxdcInstance? instance) async {
    if (!mounted) return;
    setState(() => _instance = instance);
    if (instance == null) return;

    // The store entry only changes when the instance moves to another version,
    // which happens once, when the app is started after an update was
    // published; looking it up again on every update to the app's state would
    // throw the decoded icon away for nothing.
    final cached = _app;
    if (cached != null &&
        cached.appId == instance.appId &&
        cached.version == instance.version) {
      return;
    }
    final app = await WebxdcService.appNamed(instance.appId, instance.version);
    if (!mounted) return;
    setState(() => _app = app);
  }

  @override
  Widget build(BuildContext context) {
    final instance = _instance;
    if (instance == null) {
      return const SizedBox.shrink();
    }
    return _card(context, instance, _app);
  }

  /// Downloading and verifying the bundle happens here and nowhere else: a
  /// message arriving in a chat never causes a fetch, only this tap does.
  Future<void> _start(BuildContext context, WebxdcInstance instance) async {
    final messenger = ScaffoldMessenger.of(context);
    final unavailable = context.lang.webxdcUnavailable;
    final languages = readerLanguages(context);

    final launch = await WebxdcHost.prepare(instance.instanceId, languages);
    if (launch.failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(unavailable)));
      return;
    }
    if (!context.mounted) return;
    await context.navPush(WebxdcAppView(launch: launch));
  }

  Widget _card(
    BuildContext context,
    WebxdcInstance instance,
    WebxdcApp? app,
  ) {
    final subtitle = instance.document ?? instance.summary;
    // The card sits on a message bubble, whose color is the same in either
    // theme, so what it is drawn in follows the bubble and not the surface.
    final foreground = widget.info.textColor;
    final secondary = foreground.withAlpha(180);

    // The whole card starts the app; the chevron is what says so.
    return GestureDetector(
      onTap: () => _start(context, instance),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.info.color,
          borderRadius: widget.borderRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WebxdcAppIcon(
              app: app,
              size: 40,
              radius: 8,
              color: foreground,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    // The store name in the reader's language, not anything
                    // the running app chose.
                    app == null
                        ? instance.appId
                        : WebxdcService.localizedName(
                            app,
                            readerLanguages(context),
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            FaIcon(
              FontAwesomeIcons.angleRight,
              size: 16,
              color: secondary,
            ),
          ],
        ),
      ),
    );
  }
}
