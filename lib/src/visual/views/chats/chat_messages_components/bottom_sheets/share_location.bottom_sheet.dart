import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/live_location.dart';
import 'package:twonly/core/database/app/groups/table.dart';
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

  String _label(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = seconds % 3600 ~/ 60;
    if (hours == 0) return context.lang.liveLocationMinutes(minutes);
    if (minutes == 0) return context.lang.liveLocationHours(hours);
    return context.lang.liveLocationHoursMinutes(hours, minutes);
  }

  Future<void> _pickCustom() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => _CustomDurationPicker(initialSeconds: _duration),
    );
    if (picked != null && mounted) setState(() => _duration = picked);
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
                            label: Text(_label(seconds)),
                            selected: _duration == seconds,
                            onSelected: _busy
                                ? null
                                : (_) => setState(() => _duration = seconds),
                          ),
                        ChoiceChip(
                          avatar:
                              LiveLocationService.durations.contains(_duration)
                              ? Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                )
                              : null,
                          label: Text(
                            LiveLocationService.durations.contains(_duration)
                                ? context.lang.liveLocationCustom
                                : _label(_duration),
                          ),
                          selected: !LiveLocationService.durations.contains(
                            _duration,
                          ),
                          onSelected: _busy ? null : (_) => _pickCustom(),
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

class _CustomDurationPicker extends StatefulWidget {
  const _CustomDurationPicker({required this.initialSeconds});
  final int initialSeconds;
  @override
  State<_CustomDurationPicker> createState() => _CustomDurationPickerState();
}

class _CustomDurationPickerState extends State<_CustomDurationPicker> {
  /// The wheel stops at 23 h 59 min, just below the 24 hour limit.
  static const int _maxHours = 23;

  late int _hours = (widget.initialSeconds ~/ 3600).clamp(0, _maxHours);
  late int _minutes = widget.initialSeconds % 3600 ~/ 60;
  late final _hourController = FixedExtentScrollController(initialItem: _hours);
  late final _minuteController = FixedExtentScrollController(
    initialItem: _minutes,
  );

  int get _seconds => _hours * 3600 + _minutes * 60;

  bool get _valid =>
      _seconds >= 60 && _seconds <= LiveLocationService.maxDurationSeconds;

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  Widget _column({
    required int count,
    required String suffix,
    required FixedExtentScrollController controller,
    required ValueChanged<int> onChanged,
  }) => Expanded(
    child: CupertinoPicker(
      itemExtent: 36,
      scrollController: controller,
      onSelectedItemChanged: onChanged,
      children: [
        for (var i = 0; i < count; i++) Center(child: Text('$i $suffix')),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.lang.liveLocationDuration,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(
            height: 216,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: Theme.of(context).brightness,
              ),
              child: Row(
                children: [
                  _column(
                    count: _maxHours + 1,
                    suffix: 'h',
                    controller: _hourController,
                    onChanged: (hours) => setState(() => _hours = hours),
                  ),
                  _column(
                    count: 60,
                    suffix: 'min',
                    controller: _minuteController,
                    onChanged: (minutes) => setState(() => _minutes = minutes),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          MyButton(
            variant: MyButtonVariant.primaryMiddle,
            onPressed: _valid ? () => Navigator.pop(context, _seconds) : null,
            child: Text(context.lang.ok),
          ),
        ],
      ),
    ),
  );
}
