import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

/// The soft brand-colored circle from the store feature graphic, bleeding in
/// from the top corner. Place it first in a [Stack] behind the page.
class OnboardingBackgroundGlow extends StatelessWidget {
  const OnboardingBackgroundGlow({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width * 1.1;
    return PositionedDirectional(
      top: -size * 0.45,
      end: -size * 0.4,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                context.color.primary.withValues(alpha: 0.28),
                context.color.primary.withValues(alpha: 0.06),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Share moments / privately." with the second line on a green pill, like
/// the store feature graphic.
class OnboardingHeadline extends StatelessWidget {
  const OnboardingHeadline({this.fontSize = 42, super.key});

  final double fontSize;

  static const _pillInset = 12.0;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      height: 1.1,
      fontWeight: FontWeight.w800,
      letterSpacing: -fontSize * 0.03,
      color: context.color.onSurface,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(context.lang.onboardingHeadline, style: style),
        ),
        const SizedBox(height: 6),
        // The pill reaches out so both lines start flush.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            transform: Matrix4.translationValues(
              Directionality.of(context) == TextDirection.rtl
                  ? _pillInset
                  : -_pillInset,
              0,
              0,
            ),
            padding: const EdgeInsets.fromLTRB(_pillInset, 2, _pillInset, 6),
            decoration: BoxDecoration(
              color: context.color.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(fontSize * 0.38),
            ),
            child: Text(
              context.lang.onboardingHeadlineHighlight,
              style: style,
            ),
          ),
        ),
      ],
    );
  }
}
