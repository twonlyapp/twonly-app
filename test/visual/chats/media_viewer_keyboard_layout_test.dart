import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/visual/helpers/media_view_sizing.helper.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/media_viewer_message_input.comp.dart';

void main() {
  testWidgets('keyboard moves the input without resizing the media', (
    tester,
  ) async {
    const mediaKey = Key('media');
    const safeAreaBottomPadding = 24.0;
    final controller = TextEditingController();
    final settings = _TestSettingsChangeProvider();
    addTearDown(controller.dispose);
    addTearDown(settings.dispose);

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 690);
    addTearDown(tester.view.reset);

    Future<void> pumpWithKeyboardInset(double keyboardInset) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsChangeProvider>.value(
          value: settings,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(360, 690),
                padding: EdgeInsets.only(
                  bottom: keyboardInset == 0 ? safeAreaBottomPadding : 0,
                ),
                viewPadding: const EdgeInsets.only(
                  bottom: safeAreaBottomPadding,
                ),
                viewInsets: EdgeInsets.only(bottom: keyboardInset),
              ),
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                body: SafeArea(
                  maintainBottomViewPadding: true,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const MediaViewSizingHelper(
                        requiredHeight: 55,
                        bottomNavigation: SizedBox.shrink(),
                        child: SizedBox(key: mediaKey),
                      ),
                      MediaViewerMessageInput(
                        controller: controller,
                        safeAreaBottomPadding: safeAreaBottomPadding,
                        onSubmitted: (_) {},
                        onSendPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpWithKeyboardInset(0);
    final mediaSizeWithoutKeyboard = tester.getSize(find.byKey(mediaKey));

    await pumpWithKeyboardInset(300);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(mediaKey)), mediaSizeWithoutKeyboard);
    expect(tester.widget<Positioned>(find.byType(Positioned)).bottom, 276);
  });
}

class _TestSettingsChangeProvider extends SettingsChangeProvider {
  @override
  ThemeMode get themeMode => ThemeMode.light;

  @override
  Color get primaryColor => Colors.blue;
}
