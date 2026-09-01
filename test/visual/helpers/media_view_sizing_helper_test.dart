import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/helpers/media_view_sizing.helper.dart';

void main() {
  const mediaKey = Key('media');
  const bottomNavigationKey = Key('bottom-navigation');

  Future<void> pumpHelper(
    WidgetTester tester, {
    required double height,
    bool useCameraEditorSizing = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 900);
    addTearDown(tester.view.reset);

    final sizingHelper = useCameraEditorSizing
        ? const MediaViewSizingHelper.cameraEditor(
            bottomNavigation: SizedBox(key: bottomNavigationKey),
            child: SizedBox(key: mediaKey),
          )
        : const MediaViewSizingHelper(
            requiredHeight: 55,
            bottomNavigation: SizedBox(key: bottomNavigationKey),
            child: SizedBox(key: mediaKey),
          );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 720)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 360,
              height: height,
              child: sizingHelper,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shrinks media to leave room for navigation on short devices', (
    tester,
  ) async {
    await pumpHelper(tester, height: 672);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(mediaKey)).height, 617);
    expect(tester.getSize(find.byKey(bottomNavigationKey)).height, 55);
  });

  testWidgets('keeps full media aspect ratio when enough height is available', (
    tester,
  ) async {
    await pumpHelper(tester, height: 800);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(mediaKey)), const Size(360, 640));
  });

  testWidgets('camera and editor sizing reserves their shared footer height', (
    tester,
  ) async {
    await pumpHelper(tester, height: 672, useCameraEditorSizing: true);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(mediaKey)).height, 613);
    expect(tester.getSize(find.byKey(bottomNavigationKey)).height, 59);
  });
}
