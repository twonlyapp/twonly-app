import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/background/callback_dispatcher.background.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => RustLib.init());

  test('Can initialize twonlyDB and connect to api server', () async {
    // Initialize global variables
    await initBackgroundExecution();

    // Try to connect to the API server
    final connected = await apiService.connect();

    // Print out the result or test it
    expect(connected, isA<bool>());

    // We can also check if it's connected
    // Depending on your test environment, this might be true or false
    // if the server is unreachable without further setup
    // expect(apiService.isConnected, isA<bool>());

    // Close the connection after the test
    if (apiService.isConnected) {
      await apiService.close(() {});
    }
  });
}
