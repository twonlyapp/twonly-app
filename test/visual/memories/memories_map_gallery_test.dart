import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/visual/views/memories/components/memories_map_gallery.comp.dart';

void main() {
  testWidgets('gallery sheet can expand and collapse by dragging its header', (
    tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MemoriesMapGallery(
            controller: controller,
            items: const [],
            onTap: (_) {},
            isLoading: false,
          ),
        ),
      ),
    );
    expect(controller.size, closeTo(0.36, 0.001));
    expect(find.text('0 memories in this area'), findsOneWidget);
    await tester.drag(
      find.text('0 memories in this area'),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(controller.size, closeTo(0.86, 0.01));
    await tester.drag(
      find.text('0 memories in this area'),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();
    expect(controller.size, closeTo(0.16, 0.01));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
