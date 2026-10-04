import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/themes/colors.dart';
import 'package:twonly/src/visual/themes/dark.dart';
import 'package:twonly/src/visual/themes/light.dart';

void main() {
  test('light theme exposes the app palette', () {
    final appColors = lightTheme.extension<AppColors>();

    expect(appColors, isNotNull);
    expect(
      appColors![AppColor.chatBubbleReceived],
      const Color(0xFFF3F4F3),
    );
    expect(appColors[AppColor.chatBubbleSent], const Color(0xFFE8EBE9));
    expect(lightTheme.colorScheme.onPrimary, const Color(0xFF082117));
    expect(
      lightTheme.scaffoldBackgroundColor,
      lightTheme.colorScheme.surface,
    );
  });

  test('dark theme exposes the app palette', () {
    final appColors = darkTheme.extension<AppColors>();

    expect(appColors, isNotNull);
    expect(
      appColors![AppColor.chatBubbleReceived],
      const Color(0xFF1D201E),
    );
    expect(appColors[AppColor.chatBubbleSent], const Color(0xFF292C2A));
    expect(darkTheme.colorScheme.onPrimary, const Color(0xFF082117));
    expect(darkTheme.scaffoldBackgroundColor, darkTheme.colorScheme.surface);
  });

  test('custom dark accents receive a contrasting foreground', () {
    final theme = getDarkTheme(const Color(0xFF3A76F0));

    expect(theme.colorScheme.onPrimary, const Color(0xFFFFFFFF));
  });

  test('every app color automatically participates in theme transitions', () {
    final middle = const AppColors.light().lerp(const AppColors.dark(), 0.5);

    for (final color in AppColor.values) {
      expect(middle[color], Color.lerp(color.light, color.dark, 0.5));
    }
  });
}
