import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/onboarding/components/onboarding_brand.comp.dart';

/// Frame shared by registration and setup: the brand glow behind, a top bar
/// with the back arrow and the progress, and the step below it.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    required this.child,
    this.onBack,
    this.progress,
    this.footer,
    super.key,
  });

  final Widget child;

  /// Shows the back arrow when set. Without it the space stays empty, so
  /// the progress does not jump between steps.
  final VoidCallback? onBack;

  final Widget? progress;

  /// Shown below the step, under its button.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            const OnboardingBackgroundGlow(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: onBack == null
                                ? null
                                : IconButton(
                                    // Lines the arrow up with the text below.
                                    padding: EdgeInsets.zero,
                                    alignment: AlignmentDirectional.centerStart,
                                    icon: const BackButtonIcon(),
                                    tooltip: MaterialLocalizations.of(
                                      context,
                                    ).backButtonTooltip,
                                    onPressed: onBack,
                                  ),
                          ),
                          if (progress != null) ...[
                            Expanded(child: progress!),
                            const SizedBox(width: 48),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: child),
                  ?footer,
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One step: title, text and content sit together in the middle and scroll
/// once they no longer fit, the button stays at the bottom, also above the
/// keyboard.
class OnboardingStep extends StatelessWidget {
  const OnboardingStep({
    this.title,
    this.body,
    this.children = const [],
    this.button,
    super.key,
  });

  final String? title;
  final String? body;
  final List<Widget> children;
  final Widget? button;

  @override
  Widget build(BuildContext context) {
    final header = [
      if (title != null)
        Text(
          title!,
          style: TextStyle(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
            color: context.color.onSurface,
          ),
        ),
      if (body != null) ...[
        const SizedBox(height: 12),
        Text(
          body!,
          style: TextStyle(
            fontSize: 16,
            height: 1.45,
            color: context.color.onSurfaceVariant,
          ),
        ),
      ],
    ];
    final gap = header.isNotEmpty && children.isNotEmpty ? 32.0 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...header,
                        SizedBox(height: gap),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (button != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
            child: button,
          ),
      ],
    );
  }
}

/// One segment per setup step, filled up to the current one.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    required this.current,
    required this.total,
    super.key,
  });

  /// 1-based.
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 6,
            margin: EdgeInsetsDirectional.only(
              end: index == total - 1 ? 0 : 6,
            ),
            decoration: BoxDecoration(
              color: index < current
                  ? context.color.primary
                  : context.color.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
