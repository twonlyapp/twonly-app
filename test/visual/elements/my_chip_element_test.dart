import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/visual/elements/my_chip.element.dart';

class _LightSettings extends SettingsChangeProvider {
  @override
  ThemeMode get themeMode => ThemeMode.light;
}

void main() {
  Future<void> pump(WidgetTester tester, Widget chip) => tester.pumpWidget(
    ChangeNotifierProvider<SettingsChangeProvider>(
      create: (_) => _LightSettings(),
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme.light(primary: Colors.teal),
        ),
        home: Scaffold(body: Center(child: chip)),
      ),
    ),
  );

  Color background(WidgetTester tester) {
    final box = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    return (box.decoration! as BoxDecoration).color!;
  }

  testWidgets('a selected chip is filled, not ticked and not outlined', (
    tester,
  ) async {
    await pump(
      tester,
      MyChip(label: const Text('All contacts'), selected: true, onTap: () {}),
    );
    await tester.pumpAndSettle();
    expect(background(tester), Colors.teal);
    expect(find.byIcon(Icons.check), findsNothing);
    final box = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect((box.decoration! as BoxDecoration).border, isNull);
  });

  testWidgets('an unselected chip stays neutral', (tester) async {
    await pump(tester, MyChip(label: const Text('Family'), onTap: () {}));
    expect(background(tester), isNot(Colors.teal));
  });

  testWidgets('a tap and a long press reach their callbacks', (tester) async {
    var taps = 0;
    var longPresses = 0;
    await pump(
      tester,
      MyChip(
        label: const Text('Family'),
        onTap: () => taps++,
        onLongPress: () => longPresses++,
      ),
    );
    await tester.tap(find.text('Family'));
    await tester.longPress(find.text('Family'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(longPresses, 1);
  });
}
