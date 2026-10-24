/// Mentions contain only the account ID. Names are always resolved locally.
/// An extra leading @ escapes a literal token (including already escaped ones).
final _mentionPattern = RegExp(r'@+\[user:([1-9][0-9]{0,18})\]');

class MentionPart {
  const MentionPart(this.text, {this.userId});
  final String text;
  final int? userId;
}

int? _userId(String value) {
  final id = int.tryParse(value);
  return id != null && id > 0 ? id : null;
}

List<MentionPart> parseMentions(String text) {
  final parts = <MentionPart>[];
  var end = 0;
  for (final match in _mentionPattern.allMatches(text)) {
    if (_userId(match.group(1)!) == null) continue;
    if (match.start > end) {
      parts.add(MentionPart(text.substring(end, match.start)));
    }
    final token = match.group(0)!;
    parts.add(
      token.startsWith('@@')
          ? MentionPart(token.substring(1))
          : MentionPart(token, userId: _userId(match.group(1)!)),
    );
    end = match.end;
  }
  if (end < text.length) parts.add(MentionPart(text.substring(end)));
  return parts;
}

String mentionToken(int userId) => '@[user:$userId]';

String escapeMentionText(String text) => text.replaceAllMapped(
  _mentionPattern,
  (match) =>
      _userId(match.group(1)!) == null ? match.group(0)! : '@${match.group(0)}',
);

String resolveMentions(String text, String Function(int) displayName) =>
    parseMentions(text)
        .map(
          (part) =>
              part.userId == null ? part.text : '@${displayName(part.userId!)}',
        )
        .join();
