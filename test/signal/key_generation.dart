import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

void main() {
  group('testing api', () {
    test('testing api connection', () async {
      const offset = 100;
      const count = 400;

      var prekeys = generatePreKeys(offset, count);
      expect(count, prekeys.length);

      for (var i = 0; i < prekeys.length; i++) {
        expect(prekeys[i].id, offset + i);
      }

      prekeys += generatePreKeys(offset + count, count);
      expect(count * 2, prekeys.length);

      for (var i = 0; i < (count * 2); i++) {
        expect(prekeys[i].id, offset + i);
      }
    });
  });
}
