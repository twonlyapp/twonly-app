import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

Future<void> showPromptSheet(BuildContext context, Widget sheet) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => sheet,
  );
}

/// A compact bottom sheet with an illustration, a title, a short text and a
/// primary and secondary action.
class PromptSheet extends StatelessWidget {
  const PromptSheet({
    required this.illustration,
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    super.key,
  });

  final Widget illustration;
  final String title;
  final String description;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.color.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.color.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  illustration,
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.color.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),
                  MyButton(
                    variant: MyButtonVariant.primaryMiddle,
                    onPressed: onPrimary,
                    child: Text(primaryLabel),
                  ),
                  const SizedBox(height: 12),
                  MyButton(
                    variant: MyButtonVariant.secondaryMiddle,
                    onPressed: onSecondary,
                    child: Text(secondaryLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
