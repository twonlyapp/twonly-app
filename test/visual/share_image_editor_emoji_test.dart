import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/emoji.layer.dart';

Widget _emoji({double size = 94, double pixelRatio = 3, String emoji = '😀'}) =>
    MediaQuery(
      data: MediaQueryData(devicePixelRatio: pixelRatio),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: ScreenshotEmoji(emoji: emoji, displaySize: size),
        ),
      ),
    );

ui.Image _image(WidgetTester tester) =>
    tester.widget<RawImage>(find.byType(RawImage)).image!;

int _longestSide(ui.Image image) =>
    image.width > image.height ? image.width : image.height;

void main() {
  Future<EmojiLayerData> mountLayer(WidgetTester tester) async {
    final layer = EmojiLayerData(
      key: UniqueKey(),
      text: '😀',
      offset: const Offset(109, 109),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(body: EmojiLayer(layerData: layer)),
      ),
    );
    return layer;
  }

  double opacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find.ancestor(
          of: find.byType(ScreenshotEmoji),
          matching: find.byType(Opacity),
        ),
      )
      .opacity;

  testWidgets('emoji fades over trash and recovers when dragged away', (
    tester,
  ) async {
    final layer = await mountLayer(tester);
    final start = tester.getCenter(find.byType(ScreenshotEmoji));
    final gesture = await tester.startGesture(start);
    // Cross the gesture slop first, then move its center into the trash zone.
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    const trash = Offset(400, 560);
    final current = tester.getCenter(find.byType(ScreenshotEmoji));
    await gesture.moveBy(trash - current);
    await tester.pump();
    expect(opacity(tester), 0.5);
    expect(layer.isDeleted, isFalse);

    await gesture.moveBy(const Offset(-100, -150));
    await tester.pump();
    expect(opacity(tester), 1);
    await gesture.up();
    await tester.pump();
    expect(layer.isDeleted, isFalse);
  });

  testWidgets('releasing over trash removes the faded emoji', (tester) async {
    final layer = await mountLayer(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ScreenshotEmoji)),
    );
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    final current = tester.getCenter(find.byType(ScreenshotEmoji));
    await gesture.moveBy(const Offset(400, 560) - current);
    await tester.pump();
    expect(opacity(tester), 0.5);

    await gesture.up();
    await tester.pump();
    expect(layer.isDeleted, isTrue);
    expect(find.byType(ScreenshotEmoji), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling over trash restores opacity without deleting', (
    tester,
  ) async {
    final layer = await mountLayer(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ScreenshotEmoji)),
    );
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    final current = tester.getCenter(find.byType(ScreenshotEmoji));
    await gesture.moveBy(const Offset(400, 560) - current);
    await tester.pump();
    expect(opacity(tester), 0.5);

    await gesture.cancel();
    await tester.pump();
    expect(opacity(tester), 1);
    expect(layer.isDeleted, isFalse);
  });

  testWidgets('emoji is ready for an editor export on its first frame', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: _emoji()),
    );

    expect(_longestSide(_image(tester)), greaterThanOrEqualTo(94 * 3));
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final snapshot = boundary.toImageSync();
    final bytes = await tester.runAsync(snapshot.toByteData);
    // Widget tests use Ahem rather than the device emoji font. Its glyph must
    // still be painted into the export, with no extra capture frame required.
    expect(bytes!.buffer.asUint8List().any((byte) => byte != 0), isTrue);
    snapshot.dispose();
  });

  testWidgets(
    'enlarging uses enough pixels for the display and reuses on shrink',
    (
      tester,
    ) async {
      await tester.pumpWidget(_emoji());
      final small = _image(tester);

      await tester.pumpWidget(_emoji(size: 400));
      final large = _image(tester);
      expect(large, isNot(same(small)));
      expect(_longestSide(large), greaterThanOrEqualTo(400 * 3));
      expect(small.debugDisposed, isTrue);
      expect(tester.getSize(find.byType(RawImage)), const Size.square(400));

      await tester.pumpWidget(_emoji(size: 390));
      expect(_image(tester), same(large));
      await tester.pumpWidget(_emoji());
      expect(_image(tester), same(large));

      await tester.pumpWidget(const SizedBox.shrink());
      expect(large.debugDisposed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('moving to a denser display refreshes the emoji image', (
    tester,
  ) async {
    await tester.pumpWidget(_emoji(size: 200, pixelRatio: 1));
    final original = _image(tester);

    await tester.pumpWidget(_emoji(size: 200, pixelRatio: 4));
    expect(_image(tester), isNot(same(original)));
    expect(_longestSide(_image(tester)), greaterThanOrEqualTo(200 * 4));
  });

  testWidgets(
    'changing the emoji replaces the image at the same display size',
    (
      tester,
    ) async {
      await tester.pumpWidget(_emoji());
      final original = _image(tester);

      await tester.pumpWidget(_emoji(emoji: '👩🏽‍💻'));
      expect(_image(tester), isNot(same(original)));
      expect(original.debugDisposed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('extreme enlargement keeps image memory bounded', (tester) async {
    await tester.pumpWidget(_emoji(size: 10000));
    final image = _image(tester);
    expect(_longestSide(image), lessThanOrEqualTo(2048));

    await tester.pumpWidget(_emoji(size: 20000));
    expect(_image(tester), same(image));
    expect(tester.takeException(), isNull);
  });
}
