import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';

class LastMessageTimeComp extends StatefulWidget {
  const LastMessageTimeComp({this.message, this.dateTime, super.key});

  final Message? message;
  final DateTime? dateTime;

  @override
  State<LastMessageTimeComp> createState() => _LastMessageTimeCompState();
}

class _LastMessageTimeCompState extends State<LastMessageTimeComp> {
  Timer? updateTime;
  int lastMessageInSeconds = 0;
  DateTime? targetTime;
  StreamSubscription<MessageAction?>? _actionSubscription;

  @override
  void initState() {
    super.initState();
    _loadTargetTime();
  }

  @override
  void didUpdateWidget(LastMessageTimeComp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message?.messageId != widget.message?.messageId ||
        oldWidget.dateTime != widget.dateTime) {
      _loadTargetTime();
    }
  }

  void _loadTargetTime() {
    _actionSubscription?.cancel();
    _actionSubscription = null;

    if (widget.message != null) {
      targetTime = widget.message!.openedAt ?? widget.message!.createdAt;
      _updateSeconds();
    } else if (widget.dateTime != null) {
      targetTime = widget.dateTime;
      _updateSeconds();
    }
  }

  void _updateSeconds() {
    if (targetTime == null || !mounted) return;

    final seconds = clock.now().difference(targetTime!).inSeconds;
    setState(() {
      lastMessageInSeconds = seconds < 0 ? 0 : seconds;
    });

    var nextTickMs = 1000;
    if (lastMessageInSeconds >= 120 && lastMessageInSeconds < 3600) {
      nextTickMs = 30000;
    } else if (lastMessageInSeconds >= 3600) {
      nextTickMs = 60000;
    }

    updateTime?.cancel();
    updateTime = Timer(Duration(milliseconds: nextTickMs), _updateSeconds);
  }

  @override
  void dispose() {
    updateTime?.cancel();
    _actionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatDuration(context, lastMessageInSeconds),
      style: const TextStyle(fontSize: 12),
    );
  }
}
