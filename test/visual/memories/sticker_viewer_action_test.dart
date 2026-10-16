import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/memories/components/synchronized_viewer_actions_toolbar.comp.dart';

Widget _app({required bool showCreateSticker, VoidCallback? onCreateSticker}) {
  return MaterialApp(
    theme: lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 700,
          child: SynchronizedViewerActionsToolbarComp(
            isFavorite: false,
            onShare: () {},
            onExport: () {},
            onToggleFavorite: () {},
            onDelete: () {},
            showCreateStickerButton: showCreateSticker,
            onCreateSticker: onCreateSticker ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows and invokes sticker creation for image media', (
    tester,
  ) async {
    var invoked = false;
    await tester.pumpWidget(
      _app(
        showCreateSticker: true,
        onCreateSticker: () => invoked = true,
      ),
    );

    expect(find.text('Create sticker'), findsOneWidget);
    await tester.tap(find.text('Create sticker'));
    expect(invoked, isTrue);
  });

  testWidgets('hides sticker creation for unsupported media', (tester) async {
    await tester.pumpWidget(_app(showCreateSticker: false));

    expect(find.text('Create sticker'), findsNothing);
  });
}
