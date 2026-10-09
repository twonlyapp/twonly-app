import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/services/home_widget.service.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('twonly_widget_selection_');
    AppEnvironment.initTesting(customSupportDir: root.path);
    await Directory('${root.path}/widget').create();
  });

  tearDown(() async {
    await root.delete(recursive: true);
    AppEnvironment.initTesting();
  });

  Future<void> writeWidgets(List<Map<String, Object>> widgets) async {
    await File('${root.path}/widget/native-config.json').writeAsString(
      jsonEncode({'widgets': widgets}),
    );
  }

  test('people and groups are read as separate widget selections', () async {
    await writeWidgets([
      {
        'id': 'android:1',
        'platform': 'android',
        'group_ids': [7],
        'contact_ids': [7, -42],
      },
      {
        'id': 'android:2',
        'platform': 'android',
        'contact_ids': [8],
      },
    ]);
    final widgets = await HomeWidgetService.placedWidgets();
    expect(widgets, hasLength(2));
    expect(widgets[0].contactGroupIds, [7]);
    expect(widgets[0].contactUserIds, [7, -42]);
    expect(widgets[1].contactGroupIds, isEmpty);
    expect(widgets[1].contactUserIds, [8]);
  });

  test('existing group-only widget configurations still load', () async {
    await writeWidgets([
      {
        'id': 'android:1',
        'platform': 'android',
        'group_ids': [1, 2],
      },
    ]);
    final widget = (await HomeWidgetService.placedWidgets()).single;
    expect(widget.contactGroupIds, [1, 2]);
    expect(widget.contactUserIds, isEmpty);
  });
}
