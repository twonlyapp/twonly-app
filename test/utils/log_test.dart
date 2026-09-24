import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/log.dart';

void main() {
  late Directory dir;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('twonly_log_test_');
    AppEnvironment.initTesting(
      customCacheDir: dir.path,
      customSupportDir: dir.path,
    );
    Log.init();
  });

  tearDownAll(() => dir.deleteSync(recursive: true));

  Future<List<String>> linesContaining(List<String> needles) async {
    for (var i = 0; i < 100; i++) {
      final lines = (await loadLogFile()).split('\n');
      final found = [
        for (final needle in needles)
          lines.where((line) => line.contains(needle)).firstOrNull,
      ];
      if (!found.contains(null)) return found.cast<String>();
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('The log file never contained all of $needles');
  }

  test(
    'tags lines forwarded from Rust instead of the receiving isolate',
    () async {
      Log.rust('libsignal_protocol::session_management: forwarded line');
      Log.info('line from Dart');

      final [rustLine, dartLine] = await linesContaining([
        'forwarded line',
        'line from Dart',
      ]);

      expect(
        rustLine,
        endsWith(
          'FINE [r] [twonly] rust > '
          'libsignal_protocol::session_management: forwarded line',
        ),
      );
      expect(dartLine, contains('FINE [f] [twonly] '));
    },
  );
}
