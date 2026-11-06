import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/onboarding/components/link_logo_animation.dart';
import 'package:twonly/src/visual/views/onboarding/components/onboarding_brand.comp.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({required this.onRegister, super.key});
  final VoidCallback onRegister;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with SingleTickerProviderStateMixin {
  // Brand, headline, body, features and buttons fade in one after another.
  static const _sections = 5;

  late final AnimationController _controller;
  late final List<Animation<double>> _reveals;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _reveals = List.generate(_sections, (i) {
      final start = i * 0.12;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, start + 0.52, curve: Curves.easeOutCubic),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    for (final reveal in _reveals) {
      (reveal as CurvedAnimation).dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  Widget _reveal(int section, Widget child) {
    final animation = _reveals[section];
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const OnboardingBackgroundGlow(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          _reveal(
                            0,
                            Row(
                              children: [
                                LinkLogoAnimation(
                                  color: context.color.onSurface,
                                  size: 36,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'twonly',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    color: context.color.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 48),
                          _reveal(1, const OnboardingHeadline()),
                          const SizedBox(height: 28),
                          _reveal(
                            2,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: context.color.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  context.lang.onboardingBody,
                                  style: TextStyle(
                                    fontSize: 17,
                                    height: 1.45,
                                    color: context.color.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          _reveal(
                            3,
                            Column(
                              children: [
                                _Feature(
                                  icon: Icons.lock_outline_rounded,
                                  text: context.lang.onboardingFeatureE2e,
                                ),
                                const SizedBox(height: 14),
                                _Feature(
                                  icon: Icons.block_rounded,
                                  text: context.lang.onboardingFeatureNoAds,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 40),
                          _reveal(
                            4,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                MyButton(
                                  onPressed: widget.onRegister,
                                  child: Text(
                                    context.lang.onboardingRegisterButton,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                MyButton(
                                  onPressed: () => context.push(
                                    Routes.settingsBackupRecovery,
                                  ),
                                  variant: MyButtonVariant.secondary,
                                  child: Text(
                                    context.lang.twonlySafeRecoverBtn,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: context.color.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: context.color.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: context.color.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
