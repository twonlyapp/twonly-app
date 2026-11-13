import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:twonly/src/model/story_metadata.dart';

/// A duration is relative to every post; a deadline is shared across posts.
class StoryAvailability {
  const StoryAvailability.duration([this.duration = storyLifetime])
    : deadline = null;
  const StoryAvailability.until(DateTime this.deadline) : duration = null;

  final Duration? duration;
  final DateTime? deadline;
  static const preferenceKey = 'story_availability_v1';

  DateTime expiresAt(DateTime now) => deadline ?? now.add(duration!);

  bool isValidAt(DateTime now) {
    final expiry = expiresAt(now);
    return expiry.isAfter(now) && !expiry.isAfter(now.add(maxStoryLifetime));
  }

  static Future<StoryAvailability> load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(preferenceKey);
      if (raw == null) return const StoryAvailability.duration();
      final value = jsonDecode(raw) as Map<String, dynamic>;
      final deadline = value['deadline'] as int?;
      if (deadline != null) {
        return StoryAvailability.until(
          DateTime.fromMillisecondsSinceEpoch(deadline),
        );
      }
      final seconds = value['duration'] as int;
      final duration = Duration(seconds: seconds);
      if (duration <= Duration.zero || duration > maxStoryLifetime) {
        return const StoryAvailability.duration();
      }
      return StoryAvailability.duration(duration);
    } on Object {
      return const StoryAvailability.duration();
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      preferenceKey,
      jsonEncode({
        if (deadline != null) 'deadline': deadline!.millisecondsSinceEpoch,
        if (duration != null) 'duration': duration!.inSeconds,
      }),
    );
  }
}
