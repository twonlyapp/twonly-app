import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/user_config.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/core/user_config.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';

import '../helpers/native_database.dart';
import '../mocks/user_config.dart';

class _UserApi extends NativeTestApi {
  Exception? loadFailure;
  Exception? updateFailure;
  bool commitBeforeFailure = false;

  @override
  Future<UserConfig?> crateBridgeUserConfigUserConfigApiLoad() async {
    if (loadFailure case final error?) throw error;
    return super.crateBridgeUserConfigUserConfigApiLoad();
  }

  @override
  Future<UserConfig> crateBridgeUserConfigUserConfigApiUpdate({
    required UserConfig base,
    required UserConfig config,
  }) async {
    if (updateFailure case final error?) {
      if (commitBeforeFailure) {
        await super.crateBridgeUserConfigUserConfigApiUpdate(
          base: base,
          config: config,
        );
      }
      throw error;
    }
    return super.crateBridgeUserConfigUserConfigApiUpdate(
      base: base,
      config: config,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final api = _UserApi();
  setUpAll(() => initializeNativeDatabase(api: api));
  tearDownAll(RustLib.dispose);
  setUp(() async {
    api
      ..loadFailure = null
      ..updateFailure = null
      ..commitBeforeFailure = false;
    await locator.reset();
    locator.registerSingleton<UserService>(UserService());
    await UserService.save(
      testUserConfig(
        userId: 1,
        username: 'me',
        displayName: 'Me',
        subscriptionPlan: 'Free',
        currentSetupPage: null,
        appVersion: 192,
      ),
    );
  });
  tearDown(locator.reset);

  test('a cancelled config read is retried after resume', () async {
    api.loadFailure = Exception(
      'Database operation cancelled; retry when active',
    );
    var mutations = 0;
    await UserService.update((user) {
      mutations++;
      user.fcmToken = 'new-token';
    });
    expect(mutations, 0);

    api.loadFailure = null;
    await UserService.retryPendingUpdates();
    expect(mutations, 1);
    expect((await UserConfigApi.load())!.fcmToken, 'new-token');
    expect(userService.currentUser.fcmToken, 'new-token');
  });

  test(
    'deferred changes preserve concurrent settings and update order',
    () async {
      api.updateFailure = Exception(
        'attempted to acquire a connection on a closed pool',
      );
      await UserService.update((user) => user.fcmToken = 'old-token');
      await UserService.update((user) => user.fcmToken = 'latest-token');
      expect((await UserConfigApi.load())!.fcmToken, isNull);

      final concurrent = UserConfigApi.clone(
        config: (await UserConfigApi.load())!,
      )..displayName = 'Changed elsewhere';
      await UserConfigApi.save(config: concurrent);
      api.updateFailure = null;
      await UserService.retryPendingUpdates();
      final saved = (await UserConfigApi.load())!;
      expect(saved.fcmToken, 'latest-token');
      expect(saved.displayName, 'Changed elsewhere');
      expect(userService.currentUser.fcmToken, 'latest-token');
    },
  );

  test(
    'cancellation after persistence does not apply a toggle twice',
    () async {
      api
        ..updateFailure = Exception(
          'Database operation cancelled; retry when active',
        )
        ..commitBeforeFailure = true;
      var mutations = 0;
      await UserService.update((user) {
        mutations++;
        user.isDeveloper = !user.isDeveloper;
      });
      expect((await UserConfigApi.load())!.isDeveloper, isTrue);

      api.updateFailure = null;
      await UserService.retryPendingUpdates();
      expect(mutations, 1);
      expect(userService.currentUser.isDeveloper, isTrue);
      expect((await UserConfigApi.load())!.isDeveloper, isTrue);
    },
  );

  test(
    'enabling developer settings refreshes the user and listeners',
    () async {
      final updated = userService.onUserUpdated.first;
      await UserService.update((user) => user.isDeveloper = true);
      await updated;
      expect(userService.currentUser.isDeveloper, isTrue);
      expect((await UserConfigApi.load())!.isDeveloper, isTrue);
    },
  );

  test(
    'unchanged disk settings still refresh a stale UI configuration',
    () async {
      final persisted = UserConfigApi.clone(config: userService.currentUser)
        ..isDeveloper = true;
      await UserConfigApi.save(config: persisted);
      expect(userService.currentUser.isDeveloper, isFalse);

      final updated = userService.onUserUpdated.first;
      await UserService.update((user) => user.isDeveloper = true);
      expect(userService.currentUser.isDeveloper, isTrue);
      await updated;
    },
  );
}
