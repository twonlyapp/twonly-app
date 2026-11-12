import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/components/draggable_scrollbar.comp.dart';

void main() {
  testWidgets('a retained thumb fits after the viewport shrinks', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final height = ValueNotifier<double>(600);
    addTearDown(height.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: ValueListenableBuilder<double>(
            valueListenable: height,
            builder: (context, height, _) => SizedBox(
              width: 300,
              height: height,
              child: DraggableScrollbar(
                controller: controller,
                child: ListView.builder(
                  controller: controller,
                  itemCount: 100,
                  itemExtent: 50,
                  itemBuilder: (_, index) => Text('$index'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    controller.jumpTo(controller.position.maxScrollExtent * 0.51);
    await tester.pumpAndSettle();
    // The scroll offset was computed for a taller viewport. No new scroll
    // notification is needed to keep the thumb inside the shorter track.
    height.value = 300;
    await tester.pump();
    expect(tester.takeException(), isNull);
    height.value = 30;
    await tester.pump();
    expect(tester.takeException(), isNull);
    height.value = 500;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
