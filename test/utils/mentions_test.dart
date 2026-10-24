import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/utils/mentions.dart';

void main() {
  test('mentions resolve using the reader name without altering IDs', () {
    const text = '👋 @[user:42], meet @[user:7] and @[user:42].';
    expect(
      resolveMentions(text, (id) => {42: 'My friend', 7: 'Alice'}[id]!),
      '👋 @My friend, meet @Alice and @My friend.',
    );
    expect(
      resolveMentions(text, (id) => {42: 'Tobi', 7: 'Alina'}[id]!),
      '👋 @Tobi, meet @Alina and @Tobi.',
    );
  });

  test('canonical positive int64 IDs only', () {
    for (final text in [
      '@Alice',
      '@[user:042]',
      '@[user:-42]',
      '@[user:0]',
      '@[user:42',
      '@[user:9223372036854775808]',
      '@[user:99999999999999999999]',
    ]) {
      expect(
        parseMentions(text).where((part) => part.userId != null),
        isEmpty,
        reason: text,
      );
      expect(resolveMentions(text, (_) => 'Alice'), text);
    }
    expect(
      parseMentions('@[user:9223372036854775807]').single.userId,
      9223372036854775807,
    );
  });

  test('literal token syntax round trips without becoming a mention', () {
    for (final text in [
      '@[user:42]',
      '@@[user:42]',
      '@@@[user:42]',
      r'\@[user:42]',
      'Contact @Alice: @[user:42]',
    ]) {
      final escaped = escapeMentionText(text);
      expect(
        parseMentions(escaped).where((part) => part.userId != null),
        isEmpty,
      );
      expect(resolveMentions(escaped, (_) => 'Alice'), text);
    }
    expect(
      resolveMentions('@@[user:42] @[user:42]', (_) => 'Alice'),
      '@[user:42] @Alice',
    );
  });
}
