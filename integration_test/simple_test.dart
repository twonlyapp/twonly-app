import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => RustLib.init());
  testWidgets('Can call rust function', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.textContaining('Result: `Hello, Tom!`'), findsOneWidget);
  });
}
