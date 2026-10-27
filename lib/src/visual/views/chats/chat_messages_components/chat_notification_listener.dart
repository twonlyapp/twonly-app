import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/src/services/notifications/native.notifications.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/log.dart';

/// Acknowledges chat activity for as long as the conversation is on screen.
/// Rust decides which alerts to clear, preserving unopened media.
class ChatNotificationListener extends StatefulWidget {
  const ChatNotificationListener({
    required this.conversationId,
    required this.child,
    super.key,
  });

  final String conversationId;
  final Widget child;

  @override
  State<ChatNotificationListener> createState() =>
      _ChatNotificationListenerState();
}

class _ChatNotificationListenerState extends State<ChatNotificationListener>
    with WidgetsBindingObserver {
  StreamSubscription<List<String>>? _changes;
  StreamSubscription<void>? _arrivals;
  bool _routeIsCurrent = false;
  bool _clearing = false;
  bool _clearAgain = false;

  bool get _isVisible {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return mounted &&
        _routeIsCurrent &&
        (lifecycle == null || lifecycle == AppLifecycleState.resumed);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _arrivals = NativeNotificationService.arrivals.listen(
      (_) => unawaited(_clearNotifications()),
    );
    _changes = watchRustDatabaseChanges().listen(
      (tables) {
        if (tables.isEmpty || tables.contains('notification_outbox')) {
          unawaited(_clearNotifications());
        }
      },
      onError: (Object error) {
        Log.error('Conversation notification change stream failed: $error');
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeIsCurrent = ModalRoute.isCurrentOf(context) ?? false;
    _updateVisibility();
  }

  @override
  void didUpdateWidget(ChatNotificationListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      unawaited(
        NativeNotificationService.setConversationVisible(
          oldWidget.conversationId,
          visible: false,
        ),
      );
      _updateVisibility();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _updateVisibility();
  }

  void _updateVisibility() {
    unawaited(
      NativeNotificationService.setConversationVisible(
        widget.conversationId,
        visible: _isVisible,
      ),
    );
    unawaited(_clearNotifications());
  }

  Future<void> _clearNotifications() async {
    if (!_isVisible) return;
    if (_clearing) {
      _clearAgain = true;
      return;
    }
    _clearing = true;
    try {
      do {
        _clearAgain = false;
        await NativeNotificationService.clearConversation(
          widget.conversationId,
        );
        // An arrival during the await needs another pass. Clearing the outbox
        // also emits a change; the next pass does no writes once it is empty.
      } while (_clearAgain && _isVisible);
    } finally {
      _clearing = false;
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    _arrivals?.cancel();
    unawaited(
      NativeNotificationService.setConversationVisible(
        widget.conversationId,
        visible: false,
      ),
    );
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
