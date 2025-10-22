import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hashlib/random.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/pow.dart';
import 'package:twonly/src/views/components/animate_icon.dart';

void main() {
  group('testing utils', () {
    test('test isEmoji function', () {
      expect(isEmoji('Hallo'), false);
      expect(isEmoji('😂'), true);
      expect(isEmoji('😂😂'), false);
      expect(isEmoji('Hallo 😂'), false);
    });

    test('test proof-of-work simple', () async {
      expect(await calculatePoW(Uint8List.fromList([41, 41, 41, 41]), 6), 33);
    });

    test('test utils', () async {
      final list1 = Uint8List.fromList([41, 41, 41, 41, 41, 41, 41]);
      final list2 = Uint8List.fromList([42, 42, 42]);
      final combined = combineUint8Lists(list1, list2);
      final lists = extractUint8Lists(combined);
      expect(list1, lists[0]);
      expect(list2, lists[1]);
    });

    test('encode hex', () async {
      final list1 = Uint8List.fromList([41, 41, 41, 41, 41, 41, 41]);
      expect(list1, hexToUint8List(uint8ListToHex(list1)));
    });

    test('encoding uuid4', () async {
      final uv4 = uuid.v4();
      final uv4Bytes = Uint8List.fromList(uv4.codeUnits);
      final uv4String = utf8.decode(uv4Bytes.cast<int>());
      expect(uv4String, uv4);
    });
    test('comparing uui7', () async {
      final uv7Old = uuid.v7();
      sleep(const Duration(milliseconds: 1000));
      final uv7New = uuid.v7();
      expect(isUUIDNewer(uv7New, uv7Old), true);
    });
  });
}
