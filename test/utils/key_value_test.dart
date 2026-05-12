import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/keyvalue.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('twonly_keyvalue_test_');
    AppEnvironment.initTesting(
      customCacheDir: tempDir.path,
      customSupportDir: tempDir.path,
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('KeyValueStore Tests', () {
    test('get returns null for non-existent key', () async {
      final result = await KeyValueStore.get('non_existent');
      expect(result, isNull);
    });

    test('put stores value and get retrieves it correctly', () async {
      const key = 'test_key';
      final value = {'name': 'twonly', 'version': 1};

      await KeyValueStore.put(key, value);

      final retrieved = await KeyValueStore.get(key);
      expect(retrieved, isNotNull);
      expect(retrieved?['name'], equals('twonly'));
      expect(retrieved?['version'], equals(1));
    });

    test('delete removes stored value successfully', () async {
      const key = 'delete_key';
      final value = {'data': 'to_be_deleted'};

      await KeyValueStore.put(key, value);
      expect(await KeyValueStore.get(key), isNotNull);

      await KeyValueStore.delete(key);
      expect(await KeyValueStore.get(key), isNull);
    });

    test('delete on non-existent key completes without error', () async {
      await expectLater(KeyValueStore.delete('non_existent'), completes);
    });

    test('put overwrites existing value', () async {
      const key = 'overwrite_key';
      final initialValue = {'status': 'initial'};
      final updatedValue = {'status': 'updated'};

      await KeyValueStore.put(key, initialValue);
      var retrieved = await KeyValueStore.get(key);
      expect(retrieved?['status'], equals('initial'));

      await KeyValueStore.put(key, updatedValue);
      retrieved = await KeyValueStore.get(key);
      expect(retrieved?['status'], equals('updated'));
    });

    test('get handles corrupted JSON file gracefully by deleting it', () async {
      const key = 'corrupt_key';
      final file = File('${tempDir.path}/keyvalue/$key.json');
      await file.parent.create(recursive: true);
      await file.writeAsString('invalid json content');

      expect(file.existsSync(), isTrue);

      final retrieved = await KeyValueStore.get(key);
      expect(retrieved, isNull);
      expect(file.existsSync(), isFalse);
    });
  });
}
