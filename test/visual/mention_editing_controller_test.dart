import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/components/mention_editing_controller.dart';

void main() {
  late MentionEditingController controller;
  setUp(() => controller = MentionEditingController());
  tearDown(() => controller.dispose());

  void enter(String text, {int? caret, TextRange composing = TextRange.empty}) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret ?? text.length),
      composing: composing,
    );
  }

  test('selection creates an ID token but manual @names stay plain text', () {
    enter('Hi @Al');
    controller.insertMention(42, 'Alice Smith');
    expect(controller.text, 'Hi @Alice Smith ');
    expect(controller.messageText, 'Hi @[user:42] ');
    expect(controller.selection.extentOffset, controller.text.length);
    enter('${controller.text}and @Bob');
    expect(controller.messageText, 'Hi @[user:42] and @Bob');
  });

  test(
    'autocomplete follows the caret and excludes emails and existing mentions',
    () {
      for (final text in [
        'hello@example.org',
        'https://host/@alice',
        '@@alice',
        'hello @alice smith',
      ]) {
        enter(text);
        expect(controller.mentionQuery, isNull, reason: text);
      }
      enter('Hi @al, goodbye', caret: 6);
      expect(controller.mentionQuery, (start: 3, query: 'al'));
      controller.insertMention(42, 'Alice');
      expect(controller.text, 'Hi @Alice , goodbye');
      controller.selection = const TextSelection.collapsed(offset: 6);
      expect(controller.mentionQuery, isNull);
    },
  );

  test('drafts and edits keep IDs across local renames and Unicode names', () {
    controller
      ..loadMessage(
        '👋 @[user:42] and @[user:7]',
        (id) => id == 42 ? 'Alice' : 'Bob',
      )
      ..selection = const TextSelection.collapsed(offset: 9)
      ..refreshNames((id) => id == 42 ? 'صديقي 👋' : 'B');
    expect(controller.text, '👋 @صديقي 👋 and @B');
    expect(controller.messageText, '👋 @[user:42] and @[user:7]');
    expect(controller.selection.extentOffset, 12);
  });

  test('text inserted before a mention shifts its range', () {
    controller.loadMessage('Hi @[user:42]!', (_) => 'Alice');
    enter('Well, Hi @Alice!', caret: 6);
    expect(controller.messageText, 'Well, Hi @[user:42]!');
  });

  test(
    'backspace, forward delete and partial replacement remove a whole mention',
    () {
      for (final next in ['Hi @Alic!', 'Hi Alice!', 'Hi @AlXce!']) {
        controller.loadMessage('Hi @[user:42]!', (_) => 'Alice');
        enter(next);
        expect(controller.text, next.contains('X') ? 'Hi X!' : 'Hi !');
        expect(controller.messageText, controller.text);
      }
    },
  );

  test(
    'editing across mentions removes affected IDs and preserves later ones',
    () {
      controller.loadMessage(
        '@[user:1] and @[user:2] and @[user:3]',
        (id) => 'User $id',
      );
      // A selection starts inside the first mention and ends inside the second.
      enter('@Usreplacementer 2 and @User 3');
      expect(controller.text, 'replacement and @User 3');
      expect(controller.messageText, 'replacement and @[user:3]');
    },
  );

  test('literal tokens stay literal through editing and draft restoration', () {
    enter('Write @[user:42]');
    expect(controller.messageText, 'Write @@[user:42]');
    controller.loadMessage(controller.messageText, (_) => 'Alice');
    expect(controller.text, 'Write @[user:42]');
    expect(controller.messageText, 'Write @@[user:42]');
  });

  test('clear removes mention metadata', () {
    controller
      ..loadMessage('@[user:42]', (_) => 'Alice')
      ..clear();
    enter('@Alice');
    expect(controller.messageText, '@Alice');
  });

  test('autocomplete works with an active keyboard composing region', () {
    enter('@al', composing: const TextRange(start: 0, end: 3));
    expect(controller.mentionQuery, (start: 0, query: 'al'));
    controller.insertMention(42, 'Alice');
    expect(controller.text, '@Alice ');
    expect(controller.messageText, '@[user:42] ');
    expect(controller.value.composing, TextRange.empty);
  });
}
