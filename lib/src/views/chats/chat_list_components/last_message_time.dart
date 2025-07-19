import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/misc.dart';

class LastMessageTime extends StatefulWidget {
  const LastMessageTime({required this.message, super.key});

  final Message message;

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
    updateTime = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        lastMessageInSeconds = DateTime.now()
            .difference(widget.message.openedAt ?? widget.message.sendAt)
            .inSeconds;
        if (lastMessageInSeconds < 0) {
          lastMessageInSeconds = 0;
        }
      });
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
      formatDuration(lastMessageInSeconds),
      style: const TextStyle(fontSize: 12),
    );
  }
}
