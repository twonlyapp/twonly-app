import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/services/home_widget.service.dart';

void main() {
  tearDown(HomeWidgetService.consumeInitialTap);

  test('widget sender survives cold launch and is consumed only once', () {
    expect(
      HomeWidgetService.handleLink(Uri.parse('twonly://widget?sender_id=42')),
      isTrue,
    );
    expect(HomeWidgetService.consumeInitialTap(), (senderId: 42));
    expect(HomeWidgetService.consumeInitialTap(), isNull);
  });

  test('warm widget taps emit the sender', () async {
    final tap = HomeWidgetService.taps.first;
    HomeWidgetService.handleLink(Uri.parse('twonly://widget?sender_id=-42'));
    expect(await tap, (senderId: -42));
  });

  test('empty and invalid widget targets fall back to the chat overview', () {
    for (final link in [
      'twonly://widget',
      'twonly://widget?sender_id=',
      'twonly://widget?sender_id=not-a-number',
      'twonly://widget?sender_id=1&sender_id=2',
      'twonly://widget/other?sender_id=42',
    ]) {
      expect(HomeWidgetService.handleLink(Uri.parse(link)), isTrue);
      expect(HomeWidgetService.consumeInitialTap(), (senderId: null));
    }
  });

  test('unrelated links are left to the normal link handler', () {
    for (final link in ['https://me.twonly.eu/alice', 'twonly://other']) {
      expect(HomeWidgetService.handleLink(Uri.parse(link)), isFalse);
      expect(HomeWidgetService.consumeInitialTap(), isNull);
    }
  });
}
