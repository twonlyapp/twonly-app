import 'dart:io';

import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

/// Explains how to put a twonly widget on the home screen.
///
/// A widget can only be placed by the user, from the home screen itself —
/// neither iOS nor Android exposes an API for an app to add or configure one on
/// the user's behalf — so instructions are the most the app can offer.
class WidgetSetupGuide extends StatelessWidget {
  const WidgetSetupGuide({required this.showIntro, super.key});

  /// Whether to lead with what the feature is. Shown when the user has no
  /// widget yet; skipped when this sits under a list they can already see.
  final bool showIntro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showIntro) ...[
            Center(
              child: Icon(
                Icons.widgets_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.lang.widgetsIntroTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.lang.widgetsIntroBody,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
          ],
          Text(
            showIntro
                ? context.lang.widgetsNoneTitle
                : context.lang.widgetsAddAnother,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Platform.isIOS
                ? context.lang.widgetsSetupIos
                : context.lang.widgetsSetupAndroid,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
