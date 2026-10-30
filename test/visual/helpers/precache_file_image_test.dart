import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/visual/helpers/precache_file_image.dart';

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('twonly-precache-');
  });
  tearDown(() => directory.deleteSync(recursive: true));

  testWidgets('a damaged image can be repaired and precached again', (
    tester,
  ) async {
    final failures = <Object?>[];
    final subscription = Logger.root.onRecord.listen((record) {
      if (record.error != null) failures.add(record.error);
    });
    addTearDown(subscription.cancel);
    final file = File('${directory.path}/image.png')
      ..writeAsBytesSync([0, 1, 2, 3]);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox).first);

    expect(
      await tester.runAsync(
        () => precacheFileImage(file, context, source: 'test'),
      ),
      isFalse,
    );
    expect(tester.takeException(), isNull);
    await tester.pump();

    file.writeAsBytesSync(
      File('assets/images/default_avatar.png').readAsBytesSync(),
    );
    expect(
      await tester.runAsync(
        () => precacheFileImage(file, context, source: 'test'),
      ),
      isTrue,
      reason: failures.join('\n'),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await FileImage(file).evict();
  });
}
