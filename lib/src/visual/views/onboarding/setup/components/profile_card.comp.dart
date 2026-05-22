import 'package:flutter/material.dart';
import 'package:twonly/src/services/profile.service.dart';
import 'package:twonly/src/utils/misc.dart';

class SafetyProfileCard extends StatelessWidget {
  const SafetyProfileCard({
    required this.profile,
    required this.isSelected,
    required this.onTap,
    this.isHovered = false,
    this.onHover,
    super.key,
  });

  final Object profile;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isHovered;
  final ValueChanged<bool>? onHover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bodyMediumStyle = theme.textTheme.bodyMedium?.copyWith(
      color: context.color.onSurfaceVariant,
      height: 1.35,
    );

    final String title;
    final Widget subtitle;
    final IconData icon;
    final String? badgeText;

    if (profile is SetupProfile) {
      switch (profile as SetupProfile) {
        case SetupProfile.standard:
          title = context.lang.onboardingProfileSelectionDefaultTitle;
          subtitle = Text(
            context.lang.onboardingProfileSelectionDefaultDesc,
            style: bodyMediumStyle,
          );
          icon = Icons.bolt_rounded;
          badgeText = context.lang.onboardingProfileSelectionDefaultBadge;
        case SetupProfile.customized:
          title = context.lang.onboardingProfileSelectionCustomizeTitle;
          subtitle = Text(
            context.lang.onboardingProfileSelectionCustomizeDesc,
            style: bodyMediumStyle,
          );
          icon = Icons.tune_rounded;
          badgeText = null;
        case SetupProfile.maximum:
          title = context.lang.onboardingProfileSelectionStrictTitle;
          subtitle = RichText(
            text: TextSpan(
              style: bodyMediumStyle,
              children: formattedText(
                context,
                context.lang.onboardingProfileSelectionStrictDesc,
                boldTextColor: context.color.onSurface,
              ),
            ),
          );
          icon = Icons.lock_outline_rounded;
          badgeText = null;
      }
    } else if (profile is SecurityProfile) {
      switch (profile as SecurityProfile) {
        case SecurityProfile.normal:
          title = context.lang.securityProfileNormalTitle;
          subtitle = Text(
            context.lang.securityProfileNormalDesc,
            style: bodyMediumStyle,
          );
          icon = Icons.shield_outlined;
          badgeText = null;
        case SecurityProfile.strict:
          title = context.lang.securityProfileStrictTitle;
          subtitle = Text(
            context.lang.securityProfileStrictDesc,
            style: bodyMediumStyle,
          );
          icon = Icons.verified_user_outlined;
          badgeText = null;
      }
    } else {
      throw ArgumentError('Invalid profile type: $profile');
    }

    return MouseRegion(
      onEnter: (_) => onHover?.call(true),
      onExit: (_) => onHover?.call(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? context.color.primaryContainer.withValues(alpha: 0.12)
                : context.color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? context.color.primary
                  : (isHovered
                      ? context.color.onSurfaceVariant.withValues(alpha: 0.3)
                      : context.color.outlineVariant.withValues(alpha: 0.4)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: context.color.primary.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.color.primary.withValues(alpha: 0.1)
                      : context.color.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? context.color.primary
                      : context.color.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? context.color.primary
                                  : theme.textTheme.titleMedium?.color,
                            ),
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.color.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: context.color.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    subtitle,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
