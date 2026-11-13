import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twonly/src/model/story_availability.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('remembered durations start again for every post', () async {
    expect(
      (await StoryAvailability.load()).duration,
      const Duration(hours: 24),
    );
    const choice = StoryAvailability.duration(Duration(days: 7));
    await choice.save();
    final restored = await StoryAvailability.load();
    final first = DateTime(2026, 11, 12, 10);
    final second = first.add(const Duration(days: 2));
    expect(restored.expiresAt(first), first.add(const Duration(days: 7)));
    expect(restored.expiresAt(second), second.add(const Duration(days: 7)));
  });

  test('a vacation deadline stays fixed and cannot silently restart', () async {
    final deadline = DateTime(2026, 11, 20, 18);
    await StoryAvailability.until(deadline).save();
    final restored = await StoryAvailability.load();
    expect(restored.expiresAt(DateTime(2026, 11, 12)), deadline);
    expect(restored.expiresAt(DateTime(2026, 11, 15)), deadline);
    expect(restored.isValidAt(deadline), isFalse);
    expect(restored.isValidAt(deadline.add(const Duration(days: 1))), isFalse);
  });

  test('availability is limited to 30 days including custom deadlines', () {
    final now = DateTime(2026, 11, 12);
    expect(
      const StoryAvailability.duration(Duration(days: 30)).isValidAt(now),
      isTrue,
    );
    expect(
      const StoryAvailability.duration(Duration(days: 31)).isValidAt(now),
      isFalse,
    );
    expect(
      StoryAvailability.until(
        now.add(const Duration(days: 30, minutes: 1)),
      ).isValidAt(now),
      isFalse,
    );
    expect(StoryAvailability.until(now).isValidAt(now), isFalse);
  });
}
