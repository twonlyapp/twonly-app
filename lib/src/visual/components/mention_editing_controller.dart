import 'package:flutter/material.dart';
import 'package:twonly/src/utils/mentions.dart';
import 'package:twonly/src/visual/components/mention_style.dart';

class _MentionRange {
  const _MentionRange(this.start, this.end, this.userId);
  final int start;
  final int end;
  final int userId;
}

/// The field contains readable names; only [messageText] contains ID tokens.
class MentionEditingController extends TextEditingController {
  MentionEditingController({String text = ''}) {
    loadMessage(text, (_) => 'Unknown user');
  }

  List<_MentionRange> _mentions = [];

  Iterable<TextSelection> get mentionSelections => _mentions.map(
    (mention) =>
        TextSelection(baseOffset: mention.start, extentOffset: mention.end),
  );

  String get messageText {
    final output = StringBuffer();
    var end = 0;
    for (final mention in _mentions) {
      output
        ..write(escapeMentionText(text.substring(end, mention.start)))
        ..write(mentionToken(mention.userId));
      end = mention.end;
    }
    output.write(escapeMentionText(text.substring(end)));
    return output.toString();
  }

  void loadMessage(String message, String Function(int) displayName) {
    final output = StringBuffer();
    final mentions = <_MentionRange>[];
    for (final part in parseMentions(message)) {
      final id = part.userId;
      if (id == null) {
        output.write(part.text);
      } else {
        final start = output.length;
        output.write('@${displayName(id)}');
        mentions.add(_MentionRange(start, output.length, id));
      }
    }
    _mentions = mentions;
    super.value = TextEditingValue(
      text: output.toString(),
      selection: TextSelection.collapsed(offset: output.length),
    );
  }

  void refreshNames(String Function(int) displayName) {
    if (value.composing.isValid && !value.composing.isCollapsed) return;
    if (resolveMentions(messageText, displayName) == text) return;
    final oldSelection = selection;
    final oldMentions = _mentions;
    loadMessage(messageText, displayName);
    int translate(int offset) {
      if (offset < 0) return offset;
      var delta = 0;
      for (var i = 0; i < oldMentions.length; i++) {
        final old = oldMentions[i];
        final current = _mentions[i];
        if (offset > old.start && offset < old.end) return current.end;
        if (offset >= old.end) {
          delta += (current.end - current.start) - (old.end - old.start);
        }
      }
      return (offset + delta).clamp(0, text.length);
    }

    super.value = value.copyWith(
      selection: TextSelection(
        baseOffset: translate(oldSelection.baseOffset),
        extentOffset: translate(oldSelection.extentOffset),
        affinity: oldSelection.affinity,
        isDirectional: oldSelection.isDirectional,
      ),
    );
  }

  /// The @ query immediately before the caret, excluding existing mentions,
  /// email addresses, URLs, and an escaped/literal @.
  ({int start, String query})? get mentionQuery {
    if (!selection.isValid || !selection.isCollapsed) return null;
    final caret = selection.extentOffset;
    if (_mentions.any((m) => caret > m.start && caret <= m.end)) return null;
    final prefix = text.substring(0, caret);
    final match = RegExp(
      r'(?:^|[\s(\[{])@([^\s@\[\]{}()]*)$',
    ).firstMatch(prefix);
    if (match == null) return null;
    return (start: prefix.lastIndexOf('@'), query: match.group(1)!);
  }

  void insertMention(int userId, String displayName) {
    final query = mentionQuery;
    if (query == null) return;
    final label = '@$displayName';
    final start = query.start;
    final end = selection.extentOffset;
    value = TextEditingValue(
      text: text.replaceRange(start, end, '$label '),
      selection: TextSelection.collapsed(offset: start + label.length + 1),
    );
    _mentions = [
      ..._mentions,
      _MentionRange(start, start + label.length, userId),
    ]..sort((a, b) => a.start.compareTo(b.start));
    notifyListeners();
  }

  @override
  set value(TextEditingValue next) {
    final previous = super.value;
    if (previous.text != next.text) {
      var start = 0;
      while (start < previous.text.length &&
          start < next.text.length &&
          previous.text.codeUnitAt(start) == next.text.codeUnitAt(start)) {
        start++;
      }
      var oldEnd = previous.text.length;
      var newEnd = next.text.length;
      while (oldEnd > start &&
          newEnd > start &&
          previous.text.codeUnitAt(oldEnd - 1) ==
              next.text.codeUnitAt(newEnd - 1)) {
        oldEnd--;
        newEnd--;
      }
      final inserted = next.text.substring(start, newEnd);
      var expandedStart = start;
      var expandedEnd = oldEnd;
      for (final mention in _mentions) {
        if ((start < mention.end && oldEnd > mention.start) ||
            (start == oldEnd && start > mention.start && start < mention.end)) {
          if (mention.start < expandedStart) expandedStart = mention.start;
          if (mention.end > expandedEnd) expandedEnd = mention.end;
        }
      }
      final delta = inserted.length - (expandedEnd - expandedStart);
      _mentions = [
        for (final mention in _mentions)
          if (mention.end <= expandedStart)
            mention
          else if (mention.start >= expandedEnd)
            _MentionRange(
              mention.start + delta,
              mention.end + delta,
              mention.userId,
            ),
      ];
      if (expandedStart != start || expandedEnd != oldEnd) {
        next = TextEditingValue(
          text: previous.text.replaceRange(
            expandedStart,
            expandedEnd,
            inserted,
          ),
          selection: TextSelection.collapsed(
            offset: expandedStart + inserted.length,
          ),
        );
      }
    }
    super.value = next;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    final spans = <InlineSpan>[];
    final composing = withComposing && value.isComposingRangeValid
        ? value.composing
        : TextRange.empty;
    void append(int start, int end, {bool mention = false}) {
      if (start == end) return;
      final boundaries = <int>{
        start,
        end,
        if (composing.start > start && composing.start < end) composing.start,
        if (composing.end > start && composing.end < end) composing.end,
      }.toList()..sort();
      for (var i = 0; i < boundaries.length - 1; i++) {
        final from = boundaries[i];
        final to = boundaries[i + 1];
        final isComposing =
            composing.isValid && from >= composing.start && to <= composing.end;
        var spanStyle = mention
            ? mentionTextStyle.copyWith(color: style?.color)
            : null;
        if (isComposing) {
          spanStyle = (spanStyle ?? const TextStyle()).copyWith(
            decoration: TextDecoration.underline,
          );
        }
        spans.add(TextSpan(text: text.substring(from, to), style: spanStyle));
      }
    }

    var end = 0;
    for (final mention in _mentions) {
      append(end, mention.start);
      append(mention.start, mention.end, mention: true);
      end = mention.end;
    }
    append(end, text.length);
    return TextSpan(style: style, children: spans);
  }
}
