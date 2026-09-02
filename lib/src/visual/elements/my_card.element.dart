import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';

/// The app's standard tappable card: a tinted circular icon, a title with
/// supporting text, and a chevron.
///
/// Grew out of the backup recovery options, which are the reference for how
/// this kind of row should look; every other place that needs the same shape
/// uses this rather than rebuilding it, so they stay in step.
class MyCard extends StatelessWidget {
  const MyCard({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.onTap,
    this.accentColor,
    this.trailing,
    this.titleColor,
  });

  /// `IconData` or `FaIconData`, matching the rest of the app's icon handling.
  final dynamic icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  /// Tints the icon and its circle. Defaults to the theme's primary colour;
  /// pass an error colour to mark the card's subject as needing attention.
  final Color? accentColor;

  /// Replaces the chevron. A card without `onTap` shows nothing here unless
  /// this is given.
  final Widget? trailing;

  /// Overrides the title colour, for cards whose title *is* the warning.
  final Color? titleColor;

  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? context.color.primary;
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: icon is IconData
                ? Icon(icon as IconData, color: accent, size: 24)
                : FaIcon(icon as FaIconData?, color: accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                if (subtitle case final subtitle?) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.color.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing case final trailing?) ...[
            const SizedBox(width: 3),
            trailing,
          ] else if (onTap != null) ...[
            const SizedBox(width: 3),
            Icon(
              Icons.chevron_right_rounded,
              color: context.color.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );

    return Card(
      elevation: 0,
      color: context.color.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: onTap == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(_radius),
              onTap: onTap,
              child: content,
            ),
    );
  }
}
