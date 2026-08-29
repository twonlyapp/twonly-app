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

    // Check the API connection state
    final state = await RustApi.connectionState();

    // Print out the result or test it
    expect(state, isA<ApiConnectionState>());
  });
}
