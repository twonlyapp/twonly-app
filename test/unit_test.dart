import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/pow.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';

void main() {
  group('testing utils', () {
    test('test isEmoji function', () {
      expect(isOneEmoji('Hallo'), false);
      expect(isOneEmoji('😂'), true);
      expect(isOneEmoji('😂😂'), false);
      expect(isOneEmoji('Hallo 😂'), false);
      for (final icon in EmojiAnimationComp.animatedIcons.keys) {
        expect(isOneEmoji(icon), true);
      }
    });

    test('test proof-of-work simple', () async {
      // ignore: prefer_single_quotes
      expect(await calculatePoW("testing", 10), 783);
    });

    test('encode hex', () async {
      final list1 = Uint8List.fromList([41, 41, 41, 41, 41, 41, 41]);
      expect(list1, hexToUint8List(uint8ListToHex(list1)));
    });
  });
}
