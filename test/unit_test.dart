import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hashlib/random.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:libsignal_protocol_dart/src/ecc/ed25519.dart';
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

    test('encode hex', () async {
      final list1 = Uint8List.fromList([41, 41, 41, 41, 41, 41, 41]);
      expect(list1, hexToUint8List(uint8ListToHex(list1)));
    });

    test('Zero inputs produce all-zero UUID', () {
      expect(
        getUUIDforDirectChat(0, 0),
        '00000000-0000-0000-0000-000000000000',
      );
      expect(getUUIDforDirectChat(0, 0).length, uuid.v1().length);
    });

    test('Max int values (0x7fffffff)', () {
      const max32 = 0x7fffffff; // 2147483647
      expect(
        getUUIDforDirectChat(max32, max32),
        '00000000-7fff-ffff-0000-00007fffffff',
      );
    });

    test('Bigger goes front', () {
      expect(
        getUUIDforDirectChat(1, 0),
        '00000000-0000-0001-0000-000000000000',
      );
      expect(
        getUUIDforDirectChat(0, 1),
        '00000000-0000-0001-0000-000000000000',
      );
    });

    test('Arbitrary within 32-bit range', () {
      expect(
        getUUIDforDirectChat(0x12345678, 0x0abcdef0),
        '00000000-1234-5678-0000-00000abcdef0',
      );
    });

    test('Reject values > 0x7fffffff', () {
      expect(() => getUUIDforDirectChat(0x80000000, 0), throwsArgumentError);
    });

    test('sign and verify', () {
      final keyPair = generateIdentityKeyPair();
      final message = Uint8List(10);

      final random = getRandomUint8List(32);

      final signature =
          sign(keyPair.getPrivateKey().serialize(), message, random);

      expect(
        verifySig(keyPair.getPublicKey().serialize(), message, signature),
        true,
      );
    });
  });
}
