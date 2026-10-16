import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/daos/stories.dao.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/story_expiry_timer.dart';

class _RecordedTimer implements Timer {
  _RecordedTimer(this.duration, this.callback);

  final Duration duration;
  final void Function() callback;
  bool _active = true;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;

  @override
  void cancel() => _active = false;

  void fire() {
    if (!_active) return;
    _active = false;
    callback();
  }
}

void main() {
  test('an open story expires exactly at its lifetime boundary', () {
    late _RecordedTimer scheduled;
    var expired = false;
    final timer = StoryExpiryTimer(
      timerFactory: (duration, callback) =>
          scheduled = _RecordedTimer(duration, callback),
    );
    final postedAt = DateTime(2026, 1, 1, 12);

    timer.schedule(
      postedAt: postedAt,
      now: postedAt,
      onExpired: () => expired = true,
    );
    expect(scheduled.duration, storyLifetime);
    expect(expired, isFalse);
    scheduled.fire();
    expect(expired, isTrue);
  });

  test('rescheduling cancels the previous story expiry', () {
    final scheduled = <_RecordedTimer>[];
    var expirations = 0;
    final timer = StoryExpiryTimer(
      timerFactory: (duration, callback) {
        final recorded = _RecordedTimer(duration, callback);
        scheduled.add(recorded);
        return recorded;
      },
    );
    final now = DateTime(2026, 1, 1, 12);

    timer
      ..schedule(
        postedAt: now.subtract(storyLifetime - const Duration(seconds: 1)),
        now: now,
        onExpired: () => expirations++,
      )
      ..schedule(
        postedAt: now,
        now: now,
        onExpired: () => expirations++,
      );
    expect(scheduled.first.isActive, isFalse);
    scheduled.first.fire();
    expect(expirations, 0);
    scheduled.last.fire();
    expect(expirations, 1);
  });
}
