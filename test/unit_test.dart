import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/views/components/animate_icon.dart';

void main() {
  group('isEmoji', () {
    test('test isEmoji function', () {
      expect(isEmoji('Hallo'), false);
      expect(isEmoji('😂'), true);
      expect(isEmoji('😂😂'), false);
      expect(isEmoji('Hallo 😂'), false);
    });
  });
}
