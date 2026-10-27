import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/user_config.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';

import '../helpers/native_database.dart';
import '../mocks/user_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeNativeDatabase);
  tearDownAll(RustLib.dispose);
  setUp(() async {
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
