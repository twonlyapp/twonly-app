import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/visual/components/custom_color_picker_dialog.comp.dart';

class _TestSettingsChangeProvider extends SettingsChangeProvider {
  @override
  ThemeMode get themeMode => ThemeMode.light;
}

void main() {
  testWidgets('lays out the color wheel in an AlertDialog', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsChangeProvider>(
        create: (_) => _TestSettingsChangeProvider(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CustomColorPickerDialog(initialColor: Colors.blue),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Slider), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
