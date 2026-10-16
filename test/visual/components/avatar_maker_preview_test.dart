import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingAvatarController extends NonPersistentAvatarMakerController {
  int drawCalls = 0;

  @override
  String drawAvatarSVG() {
    drawCalls++;
    return super.drawAvatarSVG();
  }
}

void main() {
  testWidgets('reuses the generated preview and refreshes after edits', (
    tester,
  ) async {
    final controller = _CountingAvatarController();
    addTearDown(controller.dispose);

    Future<void> pumpPreview() => tester.pumpWidget(
      MaterialApp(home: AvatarMakerAvatar(controller: controller)),
    );

    await pumpPreview();
    await tester.pumpAndSettle();
    final initialDrawCalls = controller.drawCalls;
    final initialSvg = controller.displayedAvatarSVG;

    // A parent rebuild must not regenerate the unchanged avatar SVG.
    await pumpPreview();
    await tester.pumpAndSettle();
    expect(controller.drawCalls, initialDrawCalls);

    controller.selectedOptions[PropertyCategoryIds.SkinColor] =
        SkinColors.Black;
    controller.updatePreview();
    await tester.pumpAndSettle();
    expect(controller.drawCalls, initialDrawCalls + 1);
    expect(controller.displayedAvatarSVG, isNot(initialSvg));
    expect(
      tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader,
      SvgStringLoader(controller.displayedAvatarSVG),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
