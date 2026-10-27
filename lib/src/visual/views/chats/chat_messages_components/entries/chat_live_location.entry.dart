import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/location_map.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';
import 'package:twonly/src/visual/views/chats/live_location_map.view.dart';

class ChatLiveLocationEntry extends StatefulWidget {
  const ChatLiveLocationEntry({
    required this.message,
    required this.location,
    required this.borderRadius,
    required this.info,
    super.key,
  });
  final StoredMessage message;
  final LiveLocationData location;
  final BorderRadius borderRadius;
  final BubbleInfo info;
  @override
  State<ChatLiveLocationEntry> createState() => _ChatLiveLocationEntryState();
}

class _ChatLiveLocationEntryState extends State<ChatLiveLocationEntry> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    final ended =
        location.stopped ||
        DateTime.now().millisecondsSinceEpoch >= location.expiresAtMs.toInt();
    return SizedBox(
      width: 260,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Material(
          color: widget.info.color,
          child: InkWell(
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => LiveLocationMapView(message: widget.message),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 140,
                  child: location.hasLatitude()
                      ? IgnorePointer(
                          child: LocationMap(
                            latitude: location.latitude,
                            longitude: location.longitude,
                          ),
                        )
                      : Center(
                          child: Text(
                            ended
                                ? context.lang.liveLocationEnded
                                : context.lang.liveLocationWaiting,
                            style: TextStyle(color: widget.info.textColor),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ended
                            ? context.lang.liveLocationEnded
                            : context.lang.liveLocationTitle,
                        style: TextStyle(
                          color: widget.info.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (location.hasFixTimestampMs())
                        Text(
                          context.lang.liveLocationLastUpdate(
                            TimeOfDay.fromDateTime(
                              DateTime.fromMillisecondsSinceEpoch(
                                location.fixTimestampMs.toInt(),
                              ),
                            ).format(context),
                          ),
                          style: TextStyle(color: widget.info.textColor),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
