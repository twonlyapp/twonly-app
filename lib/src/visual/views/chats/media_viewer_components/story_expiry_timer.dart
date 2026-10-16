import 'dart:async';

import 'package:twonly/src/database/daos/stories.dao.dart';

typedef StoryTimerFactory =
    Timer Function(
      Duration duration,
      void Function() callback,
    );

class StoryExpiryTimer {
  StoryExpiryTimer({StoryTimerFactory? timerFactory})
    : _timerFactory = timerFactory ?? Timer.new;

  final StoryTimerFactory _timerFactory;
  Timer? _timer;

  void schedule({
    required DateTime postedAt,
    required DateTime now,
    required void Function() onExpired,
  }) {
    cancel();
    final remaining = postedAt.add(storyLifetime).difference(now);
    _timer = _timerFactory(
      remaining.isNegative ? Duration.zero : remaining,
      onExpired,
    );
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
