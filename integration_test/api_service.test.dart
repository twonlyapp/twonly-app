import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('Can initialize twonlyDB and connect to api server', () async {
    await AppEnvironment.init();
    expect(await twonlyMinimumInitialization(), isFalse);
    await userService.tryInit();

    // Check the API connection state
    final state = await RustApi.connectionState();

    // Print out the result or test it
    expect(state, isA<ApiConnectionState>());
  });
}
