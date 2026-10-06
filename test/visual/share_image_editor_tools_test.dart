import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/draw.layer.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/draw/custom_hand_signature.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/sticker_cutout_selector.dart';

Widget _app(Widget child) => MaterialApp(
  theme: lightTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('sticker selector moves its frame and confirms the selection', (
    tester,
  ) async {
    Rect? confirmedSelection;
    Size? confirmedSize;
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 300,
          height: 500,
          child: StickerCutoutSelector(
            busy: false,
            onCancel: () {},
            onConfirm: (selection, editorSize) async {
              confirmedSelection = selection;
              confirmedSize = editorSize;
            },
          ),
        ),
      ),
    );

    final target = find.byKey(const Key('stickerCutoutSelection'));
    final center = tester.getCenter(target);
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(20, 30));
    await gesture.up();
    await tester.pump();
    await tester.tap(find.byKey(const Key('stickerCutoutConfirm')));
    await tester.pump();

    expect(confirmedSize, const Size(300, 500));
    expect(confirmedSelection, isNotNull);
    expect(confirmedSelection!.center, const Offset(190, 280));
  });

  testWidgets('drawing eyedropper applies the sampled canvas color', (
    tester,
  ) async {
    var loaderCalls = 0;
    Offset? sampledPosition;
    Size? sampledSize;
    final layer = DrawLayerData(
      key: GlobalKey(),
      colorSamplerLoader: () async {
        loaderCalls++;
        Color? sampler(Offset position, Size editorSize) {
          sampledPosition = position;
          sampledSize = editorSize;
          return position.dx < 150 ? Colors.blue : Colors.teal;
        }

        return sampler;
      },
    );
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 300,
          height: 500,
          child: DrawLayer(layerData: layer, onUpdate: () {}),
        ),
      ),
    );

    final sliderRect = tester.getRect(
      find.byKey(const Key('drawingColorSlider')),
    );
    final eyedropperRect = tester.getRect(
      find.byKey(const Key('drawingEyedropper')),
    );
    expect(eyedropperRect.top, greaterThanOrEqualTo(sliderRect.bottom));

    await tester.tap(find.byKey(const Key('drawingEyedropper')));
    await tester.pump();
    expect(loaderCalls, 1);
    final target = find.byKey(const Key('drawingEyedropperTarget'));
    final targetTopLeft = tester.getTopLeft(target);
    final gesture = await tester.startGesture(
      targetTopLeft + const Offset(80, 180),
    );
    await tester.pump();

    expect(
      tester.widget<MagnifyingGlass>(find.byType(MagnifyingGlass)).color,
      Colors.blue,
    );
    expect(
      tester
          .widget<CustomHandSignature>(find.byType(CustomHandSignature))
          .currentColor,
      Colors.red,
    );

    await gesture.moveTo(targetTopLeft + const Offset(220, 300));
    await tester.pump();
    expect(
      tester.widget<MagnifyingGlass>(find.byType(MagnifyingGlass)).color,
      Colors.teal,
    );
    expect(
      tester
          .widget<CustomHandSignature>(find.byType(CustomHandSignature))
          .currentColor,
      Colors.red,
    );

    await gesture.up();
    await tester.pump();
    expect(sampledPosition, const Offset(220, 300));
    expect(sampledSize, const Size(300, 500));
    expect(
      tester
          .widget<CustomHandSignature>(find.byType(CustomHandSignature))
          .currentColor,
      Colors.teal,
    );
    expect(find.byKey(const Key('drawingEyedropperTarget')), findsNothing);
  });
}
