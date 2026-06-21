import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

void showPasswordlessRecoveryInfoSheet(BuildContext context) {
  // ignore: inference_failure_on_function_invocation
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return const PasswordlessRecoveryInfoSheet();
    },
  );
}

class PasswordlessRecoveryInfoSheet extends StatelessWidget {
  const PasswordlessRecoveryInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.color.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: context.color.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  context.lang.passwordlessRecoveryInfoHowItWorks,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              context.lang.passwordlessRecoveryInfoHowItWorksDesc,
            ),
            const SizedBox(height: 16),
            Text(
              context.lang.passwordlessRecoveryInfoWhySecondFactor,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.lang.passwordlessRecoveryInfoWhySecondFactorDesc,
            ),
            const SizedBox(height: 32),
            MyButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.lang.passwordlessRecoveryInfoGotIt),
            ),
          ],
        ),
      ),
    );
  }
}
