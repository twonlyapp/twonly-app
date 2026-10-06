import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('detaches from an external controller when disposed', (
    tester,
  ) async {
    final controller = NonPersistentAvatarMakerController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AvatarMakerCustomizer(
          controller: controller,
          scaffoldHeight: 500,
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    controller.updatePreview(newAvatarMakerSVG: '<svg></svg>');
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
