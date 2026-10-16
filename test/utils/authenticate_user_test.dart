import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
// Use the plugin's platform interface to simulate native authentication results.
// ignore: depend_on_referenced_packages
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/utils/misc.dart';

void main() {
  late LocalAuthPlatform previousPlatform;
  late Level previousLogLevel;
  late StreamSubscription<LogRecord> subscription;
  late List<LogRecord> records;

  setUp(() {
    previousPlatform = LocalAuthPlatform.instance;
    previousLogLevel = Logger.root.level;
    Logger.root.level = Level.ALL;
    records = [];
    subscription = Logger.root.onRecord.listen(records.add);
  });

  tearDown(() async {
    LocalAuthPlatform.instance = previousPlatform;
    Logger.root.level = previousLogLevel;
    await subscription.cancel();
  });

  for (final code in [
    LocalAuthExceptionCode.userCanceled,
    LocalAuthExceptionCode.systemCanceled,
  ]) {
    for (final force in [true, false]) {
      test(
        '${code.name} denies access without error logs (force: $force)',
        () async {
          LocalAuthPlatform.instance = _AuthPlatform(
            error: LocalAuthException(code: code),
          );

          expect(await authenticateUser('Reopen media', force: force), isFalse);
          expect(
            records.where((record) => record.level >= Level.WARNING),
            isEmpty,
          );
        },
      );
    }
  }

  test('unexpected authentication errors are still logged', () async {
    LocalAuthPlatform.instance = _AuthPlatform(
      error: const LocalAuthException(code: LocalAuthExceptionCode.deviceError),
    );

    expect(await authenticateUser('Reopen media'), isFalse);
    expect(records.single.level, Level.SHOUT);
    expect(records.single.message, contains('deviceError'));
  });

  test(
    'optional authentication still allows devices without credentials',
    () async {
      LocalAuthPlatform.instance = _AuthPlatform(
        error: const LocalAuthException(
          code: LocalAuthExceptionCode.noCredentialsSet,
        ),
      );

      expect(await authenticateUser('Reopen media', force: false), isTrue);
      expect(await authenticateUser('Reopen media'), isFalse);
    },
  );
}

class _AuthPlatform extends LocalAuthPlatform {
  _AuthPlatform({required this.error});

  final LocalAuthException error;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    throw error;
  }
}
