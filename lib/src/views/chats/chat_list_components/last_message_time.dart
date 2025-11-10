import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';

class LastMessageTime extends StatefulWidget {
  const LastMessageTime({this.message, this.dateTime, super.key});

  final Message? message;
  final DateTime? dateTime;

  @override
  State<LastMessageTime> createState() => _LastMessageTimeState();
}

class _LastMessageTimeState extends State<LastMessageTime> {
  Timer? updateTime;
  int lastMessageInSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Change the color every 200 milliseconds
    updateTime =
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (widget.message != null) {
        final lastAction = await twonlyDB.messagesDao
            .getLastMessageAction(widget.message!.messageId);
        lastMessageInSeconds = DateTime.now()
            .difference(lastAction?.actionAt ?? widget.message!.createdAt)
            .inSeconds;
      } else if (widget.dateTime != null) {
        lastMessageInSeconds =
            DateTime.now().difference(widget.dateTime!).inSeconds;
      }
      if (mounted) {
        setState(() {
          if (lastMessageInSeconds < 0) {
            lastMessageInSeconds = 0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    updateTime?.cancel();
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
