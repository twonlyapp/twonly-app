import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:twonly/core/bridge.dart' show FlameState;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';

class FlameCounterWidget extends StatefulWidget {
  const FlameCounterWidget({
    this.groupId,
    this.contactId,
    this.group,
    this.state,
    this.prefix = false,
    super.key,
  });
  final String? groupId;
  final int? contactId;
  final Group? group;

  /// A parent snapshot avoids one native watch for each chat-list row.
  final FlameState? state;
  final bool prefix;

  @override
  State<FlameCounterWidget> createState() => _FlameCounterWidgetState();
}

const emptyFlameState = FlameState(
  counter: 0,
  isExpiring: false,
  isBestFriend: false,
);

class _FlameCounterWidgetState extends State<FlameCounterWidget>
    with WidgetsBindingObserver {
  FlameState _state = emptyFlameState;
  StreamSubscription<FlameState>? _subscription;
  Timer? _dayRefresh;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_subscribe());
  }

  @override
  void didUpdateWidget(FlameCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.group?.groupId != oldWidget.group?.groupId ||
        widget.groupId != oldWidget.groupId ||
        widget.contactId != oldWidget.contactId ||
        (widget.state == null) != (oldWidget.state == null)) {
      _state = emptyFlameState;
      unawaited(_subscribe());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.state == null) {
      unawaited(_subscribe());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    unawaited(_subscription?.cancel());
    _dayRefresh?.cancel();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final generation = ++_generation;
    _dayRefresh?.cancel();
    final previous = _subscription;
    _subscription = null;
    unawaited(previous?.cancel());
    if (!mounted || generation != _generation || widget.state != null) return;

    var groupId = widget.group?.groupId ?? widget.groupId;
    if (groupId == null && widget.contactId != null) {
      final groups = await rust_groups.listGroups(
        input: db_groups.GroupQuery(
          filter: db_groups.GroupFilter.directContact,
          contactId: widget.contactId,
        ),
        transaction: currentDatabaseSession(),
      );
      groupId = groups.firstOrNull?.groupId;
    }
    if (!mounted || generation != _generation || groupId == null) return;
    final watchedGroupId = groupId;
    _subscription =
        watchRustDatabase(
          (control) => rust_groups.watchGroupFlame(
            group: watchedGroupId,
            control: control,
          ),
        ).listen((value) {
          if (mounted && generation == _generation) _apply(value);
        });
    final now = clock.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _dayRefresh = Timer(
      tomorrow.difference(now),
      () => unawaited(_subscribe()),
    );
  }

  void _apply(FlameState state) {
    if (!mounted || state == _state) return;
    setState(() => _state = state);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state ?? _state;
    final flameCounter = state.counter;
    if (flameCounter < 1) return Container();

    var flameEmoji = '🔥';

    if (state.isBestFriend) flameEmoji = '❤️‍🔥';
    if (flameCounter == 100) flameEmoji = '💯';

    if (flameCounter >= 365 && flameCounter % 365 == 0) {
      flameEmoji = '🎂';
    }

    return Row(
      children: [
        if (widget.prefix) const SizedBox(width: 5),
        if (widget.prefix) const Text('•'),
        if (widget.prefix) const SizedBox(width: 5),
        if (flameCounter != 100)
          Text(
            flameCounter.toString(),
            style: const TextStyle(fontSize: 13),
          ),
        SizedBox(
          height: 15,
          child: EmojiAnimationComp(
            emoji: flameEmoji,
          ),
        ),
        if (state.isExpiring)
          const SizedBox(
            height: 11,
            child: EmojiAnimationComp(
              emoji: '⌛',
              repeat: false,
            ),
          ),
      ],
    );
  }
}
