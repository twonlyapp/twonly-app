import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/live_location.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/live_location.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class ShareLocationView extends StatefulWidget {
  const ShareLocationView({required this.group, super.key});
  final Group group;
  @override
  State<ShareLocationView> createState() => _ShareLocationViewState();
}

class _ShareLocationViewState extends State<ShareLocationView> {
  LiveLocationSession? _session;
  bool _loading = true;
  bool _busy = false;
  int _duration = 600;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final session = await LiveLocationService.state();
      if (mounted) {
        setState(() {
          _session = session;
          _loading = false;
        });
      }
    } on Object {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await LiveLocationService.start(
        groupId: widget.group.groupId,
        durationSeconds: _duration,
        title: context.lang.liveLocationTitle,
        body: context.lang.liveLocationNotificationBody,
        stopLabel: context.lang.liveLocationStop,
      );
      if (mounted) Navigator.pop(context);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.lang.liveLocationStartFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    if (_busy || _session == null) return;
    setState(() => _busy = true);
    try {
      await LiveLocationService.stopInChat(
        _session!.sessionId,
        widget.group.groupId,
      );
      if (mounted) setState(() => _session = null);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.lang.liveLocationStopFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.lang.liveLocationTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(context.lang.liveLocationExplanation),
                  const SizedBox(height: 12),
                  if (_session?.groupIds.contains(widget.group.groupId) ??
                      false) ...[
                    Text(context.lang.liveLocationAlreadySharing),
                    MyButton(
                      variant: MyButtonVariant.primaryMiddle,
                      onPressed: _busy ? null : _stop,
                      child: Text(context.lang.liveLocationStop),
                    ),
                  ] else ...[
                    Text(context.lang.liveLocationDuration),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final seconds in LiveLocationService.durations)
                          ChoiceChip(
                            label: Text(
                              seconds < 3600
                                  ? context.lang.liveLocationMinutes(
                                      seconds ~/ 60,
                                    )
                                  : context.lang.liveLocationHours(
                                      seconds ~/ 3600,
                                    ),
                            ),
                            selected: _duration == seconds,
                            onSelected: _busy
                                ? null
                                : (_) => setState(() => _duration = seconds),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MyButton(
                      variant: MyButtonVariant.primaryMiddle,
                      onPressed: _busy ? null : _start,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.lang.liveLocationStart),
                    ),
                  ],
                ],
              ),
      ),
    ),
  );
}
