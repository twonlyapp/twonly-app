import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/live_location.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/location_map.dart';

class LiveLocationMapView extends StatefulWidget {
  const LiveLocationMapView({required this.message, super.key});
  final Message message;
  @override
  State<LiveLocationMapView> createState() => _LiveLocationMapViewState();
}

class _LiveLocationMapViewState extends State<LiveLocationMapView> {
  late final Stream<Message?> _message = twonlyDB.messagesDao
      .getMessageById(widget.message.messageId)
      .watchSingleOrNull();
  Timer? _timer;
  bool _stopping = false;
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

  Future<void> _stop(String session) async {
    setState(() => _stopping = true);
    try {
      await LiveLocationService.stopInChat(session, widget.message.groupId);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.lang.liveLocationStopFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.lang.liveLocationTitle)),
    body: StreamBuilder<Message?>(
      stream: _message,
      initialData: widget.message,
      builder: (context, snapshot) {
        final message = snapshot.data;
        final location = message == null || message.isDeletedFromSender
            ? null
            : LiveLocationService.decode(message.additionalMessageData);
        if (location == null) {
          return Center(child: Text(context.lang.liveLocationEnded));
        }
        final ended =
            location.stopped ||
            DateTime.now().millisecondsSinceEpoch >=
                location.expiresAtMs.toInt();
        return Column(
          children: [
            Expanded(
              child: location.hasLatitude()
                  ? LocationMap(
                      latitude: location.latitude,
                      longitude: location.longitude,
                      interactive: true,
                    )
                  : Center(
                      child: Text(
                        ended
                            ? context.lang.liveLocationEnded
                            : context.lang.liveLocationWaiting,
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      ended
                          ? context.lang.liveLocationEnded
                          : context.lang.liveLocationTitle,
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
                      ),
                    if (!ended && message!.senderId == null)
                      FilledButton(
                        onPressed: _stopping
                            ? null
                            : () => _stop(location.sessionId),
                        child: Text(context.lang.liveLocationStop),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
