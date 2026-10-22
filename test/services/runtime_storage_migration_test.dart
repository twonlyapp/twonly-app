import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/globals.dart';

void main() {
  late Directory root;
  late Directory source;
  late Directory destination;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('twonly-runtime-migration-');
    source = await Directory('${root.path}/private').create();
    destination = await Directory('${root.path}/shared').create();
  });
  tearDown(() async => root.delete(recursive: true));

  File target(String name) => File('${destination.path}/$name');
  Future<void> migrate() =>
      AppEnvironment.migrateToSharedSupportDirectory(source, destination);

  test('copies main, WAL and settings before publishing readiness', () async {
    await File('${source.path}/app_db.sqlite').writeAsBytes([1, 0, 2]);
    await File('${source.path}/app_db.sqlite-wal').writeAsBytes([3, 0, 4]);
    await Directory('${source.path}/keyvalue').create();
    await File('${source.path}/keyvalue/user.json').writeAsString('original');

    await migrate();

    expect(await target('app_db.sqlite').readAsBytes(), [1, 0, 2]);
    expect(await target('app_db.sqlite-wal').readAsBytes(), [3, 0, 4]);
    expect(await target('keyvalue/user.json').readAsString(), 'original');
    expect(target('.runtime_storage_migrated_v1').existsSync(), isTrue);
    expect(target('.runtime_storage_migrating_v1').existsSync(), isFalse);
    expect(File('${source.path}/app_db.sqlite-wal').existsSync(), isTrue);
  });

  test('resumes an owned interrupted copy including a missing WAL', () async {
    await File('${source.path}/app_db.sqlite').writeAsBytes([1, 2]);
    await File('${source.path}/app_db.sqlite-wal').writeAsBytes([3, 4]);
    await target(
      '.runtime_storage_migrating_v1',
    ).writeAsString(source.absolute.path);
    await target('app_db.sqlite').writeAsBytes([1, 2]);
    await target('app_db.sqlite-wal.migrating').writeAsBytes([3]);

    await migrate();

    expect(await target('app_db.sqlite-wal').readAsBytes(), [3, 4]);
    expect(target('.runtime_storage_migrated_v1').existsSync(), isTrue);
    expect(target('app_db.sqlite-wal.migrating').existsSync(), isFalse);
  });

  test('preserves both stores when unrecognized shared data exists', () async {
    await File('${source.path}/app_db.sqlite').writeAsBytes([1]);
    await target('app_db.sqlite').writeAsBytes([2]);

    await expectLater(migrate(), throwsStateError);

    expect(await target('app_db.sqlite').readAsBytes(), [2]);
    expect(await File('${source.path}/app_db.sqlite').readAsBytes(), [1]);
    expect(target('.runtime_storage_migrated_v1').existsSync(), isFalse);
  });

  test('rejects a pending migration from another source', () async {
    await target(
      '.runtime_storage_migrating_v1',
    ).writeAsString('/another/store');
    await expectLater(migrate(), throwsStateError);
    expect(target('.runtime_storage_migrated_v1').existsSync(), isFalse);
  });

  test(
    'a completed migration never overwrites subsequent shared writes',
    () async {
      await File('${source.path}/app_db.sqlite').writeAsBytes([1]);
      await migrate();
      await target('app_db.sqlite').writeAsBytes([2]);
      await migrate();
      expect(await target('app_db.sqlite').readAsBytes(), [2]);
    },
  );

  test('new installations become ready even without a private store', () async {
    await source.delete();
    await migrate();
    expect(target('.runtime_storage_migrated_v1').existsSync(), isTrue);
  });

  test(
    'preserves WidgetKit placements created before the first launch',
    () async {
      await File('${source.path}/app_db.sqlite').writeAsBytes([1, 2]);
      await Directory('${destination.path}/widget').create();
      await target(
        'widget/native-config.json',
      ).writeAsString('current widgets');
      await migrate();
      expect(await target('app_db.sqlite').readAsBytes(), [1, 2]);
      expect(
        await target('widget/native-config.json').readAsString(),
        'current widgets',
      );
    },
  );

  test(
    'copy failure keeps native admission closed and can be retried',
    () async {
      await File('${source.path}/app_db.sqlite').writeAsBytes([1, 2]);
      await File('${source.path}/app_db.sqlite-wal').writeAsBytes([3, 4]);
      await Directory('${source.path}/keyvalue').create();
      await File('${source.path}/keyvalue/user.json').writeAsString('original');
      await target(
        '.runtime_storage_migrating_v1',
      ).writeAsString(source.absolute.path);
      await target('keyvalue').writeAsString('blocking file');

      await expectLater(migrate(), throwsA(isA<FileSystemException>()));
      expect(target('.runtime_storage_migrated_v1').existsSync(), isFalse);
      expect(await File('${source.path}/app_db.sqlite-wal').readAsBytes(), [
        3,
        4,
      ]);

      await target('keyvalue').delete();
      await migrate();
      expect(await target('app_db.sqlite-wal').readAsBytes(), [3, 4]);
      expect(await target('keyvalue/user.json').readAsString(), 'original');
      expect(target('.runtime_storage_migrated_v1').existsSync(), isTrue);
    },
  );
}
