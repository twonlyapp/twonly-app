import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twonly/core/bridge/database/messages.dart' as rust_messages;
import 'package:twonly/core/database/app/messages/table.dart' as db_messages;
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/src/services/live_location.service.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/location_map.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class LiveLocationMapView extends StatefulWidget {
  const LiveLocationMapView({required this.message, super.key});
  final StoredMessage message;
  @override
  State<LiveLocationMapView> createState() => _LiveLocationMapViewState();
}

class _LiveLocationMapViewState extends State<LiveLocationMapView> {
  late final Stream<StoredMessage?> _message = watchRustDatabase(
    (control) => rust_messages.watchMessages(
      input: db_messages.MessageQuery(
        filter: db_messages.MessageFilter.ids,
        ids: {widget.message.messageId}.toList(),
        nowMs: clock.now().millisecondsSinceEpoch,
      ),
      control: control,
    ),
  ).map((rows) => rows.isEmpty ? null : rows.single);
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
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark,
    child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          StreamBuilder<StoredMessage?>(
            stream: _message,
            initialData: widget.message,
            builder: _buildContent,
          ),
          const _MapBackButton(),
        ],
      ),
    ),
  );

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<StoredMessage?> snapshot,
  ) {
    final message = snapshot.data;
    final location = message == null || message.isDeletedFromSender
        ? null
        : LiveLocationService.decode(message.additionalMessageData);
    if (location == null) {
      return Center(child: Text(context.lang.liveLocationEnded));
    }
    final ended =
        location.stopped ||
        DateTime.now().millisecondsSinceEpoch >= location.expiresAtMs.toInt();
    final lastUpdate = location.hasFixTimestampMs()
        ? context.lang.liveLocationLastUpdate(
            TimeOfDay.fromDateTime(
              DateTime.fromMillisecondsSinceEpoch(
                location.fixTimestampMs.toInt(),
              ),
            ).format(context),
          )
        : null;
    final status = !location.hasLatitude()
        ? null
        : ended
        ? [context.lang.liveLocationEnded, ?lastUpdate].join(' · ')
        : lastUpdate;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (location.hasLatitude())
          LocationMap(
            latitude: location.latitude,
            longitude: location.longitude,
            interactive: true,
          )
        else
          Center(
            child: Text(
              ended
                  ? context.lang.liveLocationEnded
                  : context.lang.liveLocationWaiting,
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status != null)
                  _Floating(
                    shape: const StadiumBorder(),
                    color: context.color.surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Text(
                        status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (!ended && message!.senderId == null) ...[
                  if (status != null) const SizedBox(height: 12),
                  _Floating(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: MyButton(
                      variant: MyButtonVariant.primaryMiddle,
                      onPressed: _stopping
                          ? null
                          : () => _stop(location.sessionId),
                      child: Text(context.lang.liveLocationStop),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A map overlay whose shadow spreads evenly around it. Material elevation
/// always offsets the shadow downward.
class _Floating extends StatelessWidget {
  const _Floating({required this.shape, required this.child, this.color});

  final ShapeBorder shape;
  final Color? color;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      shape: shape,
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 12,
        ),
      ],
    ),
    child: Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}

/// Where a photo sent with the location filter was taken.
class PhotoLocationMapView extends StatelessWidget {
  const PhotoLocationMapView({
    required this.latitude,
    required this.longitude,
    this.fixTimestampMs,
    super.key,
  });

  final double latitude;
  final double longitude;
  final int? fixTimestampMs;

  @override
  Widget build(BuildContext context) {
    final fixTimestampMs = this.fixTimestampMs;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            LocationMap(
              latitude: latitude,
              longitude: longitude,
              interactive: true,
            ),
            if (fixTimestampMs != null && fixTimestampMs > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.all(16),
                  child: Center(
                    child: _Floating(
                      shape: const StadiumBorder(),
                      color: context.color.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Text(
                          context.lang.photoLocationTakenAt(
                            TimeOfDay.fromDateTime(
                              DateTime.fromMillisecondsSinceEpoch(
                                fixTimestampMs,
                              ),
                            ).format(context),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const _MapBackButton(),
          ],
        ),
      ),
    );
  }
}

class _MapBackButton extends StatelessWidget {
  const _MapBackButton();

  @override
  Widget build(BuildContext context) => Positioned(
    top: 0,
    left: 0,
    child: SafeArea(
      bottom: false,
      right: false,
      minimum: const EdgeInsets.all(16),
      child: _Floating(
        shape: const CircleBorder(),
        color: Theme.of(context).colorScheme.surface,
        child: BackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    ),
  );
}
