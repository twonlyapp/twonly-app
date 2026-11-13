import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/model/json/onboarding_state.model.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/storage.dart';

class _ResetApi implements RustLibApi {
  int credentialRemovals = 0;
  bool fail = false;

  @override
  Future<void>
  crateBridgeWrapperKeyManagerRustKeyManagerRemoveLocalCredentials() async {
    credentialRemovals++;
    if (fail) throw StateError('Secure storage unavailable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final api = _ResetApi();
  late Directory root;
  late Directory private;
  late Directory shared;
  late Directory cache;
  late Directory documents;
  late Directory temporary;
  var restarts = 0;
  var restartSucceeds = true;

  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('twonly-reset-');
    private = await Directory('${root.path}/private').create();
    shared = await Directory('${root.path}/shared').create();
    cache = await Directory('${root.path}/cache').create();
    documents = await Directory('${root.path}/documents').create();
    temporary = await Directory('${root.path}/temporary').create();
    SharedPreferences.setMockInitialValues({'old_preference': 'old account'});
    restarts = 0;
    restartSucceeds = true;
    AppEnvironment.initTesting(
      customSupportDir: shared.path,
      customCacheDir: cache.path,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documents.path,
            'getTemporaryDirectory' => temporary.path,
            _ => private.path,
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('restart'), (call) async {
          restarts++;
          expect(api.credentialRemovals, 1);
          expect(File('${shared.path}/app_db.sqlite').existsSync(), isFalse);
          expect(File('${documents.path}/export.zip').existsSync(), isFalse);
          expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
          final state = await KeyValueStore.getModel<OnboardingState>(
            KeyValueKeys.onboardingState,
          );
          expect(state.openRegistration, isTrue);
          expect(state.receivedShares, isEmpty);
          return restartSucceeds ? 'ok' : 'failed';
        });
    api
      ..credentialRemovals = 0
      ..fail = false;
    await File('${private.path}/twonly.sqlite').writeAsString('old account');
    await File('${shared.path}/app_db.sqlite').writeAsString('active account');
    await Directory('${shared.path}/media').create();
    await File('${shared.path}/media/photo.jpg').writeAsString('photo');
    await File('${cache.path}/preview.jpg').writeAsString('preview');
    await File('${documents.path}/export.zip').writeAsString('old backup');
    await File('${temporary.path}/download.bin').writeAsString('old download');
  });
  tearDown(() async => root.delete(recursive: true));

  test(
    'reset clears active, private and cached data and credentials',
    () async {
      final marker = File('${shared.path}/.runtime_storage_migrated_v1');
      final lock = File('${shared.path}/app_db.sqlite.twonly-maintenance.lock');
      await marker.writeAsString('complete');
      await lock.writeAsString('');

      expect(await deleteLocalUserData(removeCredentials: true), isTrue);

      expect(api.credentialRemovals, 1);
      expect(private.listSync(), isEmpty);
      expect(cache.listSync(), isEmpty);
      expect(documents.listSync(), isEmpty);
      expect(temporary.listSync(), isEmpty);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
      expect(
        shared.listSync().map((entry) => entry.path),
        unorderedEquals([
          marker.path,
          lock.path,
        ]),
      );
      await AppEnvironment.migrateToSharedSupportDirectory(private, shared);
      expect(File('${shared.path}/app_db.sqlite').existsSync(), isFalse);
    },
  );

  test('credential failure preserves the files and allows retry', () async {
    api.fail = true;
    await expectLater(
      deleteLocalUserData(removeCredentials: true),
      throwsStateError,
    );
    expect(File('${shared.path}/app_db.sqlite').existsSync(), isTrue);
    expect(File('${private.path}/twonly.sqlite').existsSync(), isTrue);

    api.fail = false;
    await deleteLocalUserData(removeCredentials: true);
    expect(shared.listSync(), isEmpty);
  });

  test('default cleanup keeps recovery credentials', () async {
    await deleteLocalUserData();
    expect(api.credentialRemovals, 0);
    expect(shared.listSync(), isEmpty);
  });

  test(
    'registration clears old recovery state before requesting a fresh process',
    () async {
      await KeyValueStore.putAtomically(
        KeyValueKeys.onboardingState,
        OnboardingState(
          hasStartedPasswordlessRecovery: true,
          downloadAuthToken: [1, 2, 3],
          encryptionKey: [4, 5, 6],
        ).toJson(),
      );
      await prepareNewAccountRegistration(
        notificationTitle: 'twonly',
        notificationBody: 'Register a new account',
      );
      expect(restarts, 1);
      final state = await KeyValueStore.getModel<OnboardingState>(
        KeyValueKeys.onboardingState,
      );
      expect(state.hasStartedPasswordlessRecovery, isFalse);
      expect(state.downloadAuthToken, isNull);
      expect(state.encryptionKey, isNull);
    },
  );

  test('registration stops when credentials cannot be cleared', () async {
    api.fail = true;
    await expectLater(
      prepareNewAccountRegistration(
        notificationTitle: 'twonly',
        notificationBody: 'Register',
      ),
      throwsStateError,
    );
    expect(restarts, 0);
    expect(File('${shared.path}/app_db.sqlite').existsSync(), isTrue);
  });

  test(
    'registration reports a failed restart instead of using closed handles',
    () async {
      restartSucceeds = false;
      await expectLater(
        prepareNewAccountRegistration(
          notificationTitle: 'twonly',
          notificationBody: 'Register',
        ),
        throwsStateError,
      );
      expect(restarts, 1);
    },
  );
}
