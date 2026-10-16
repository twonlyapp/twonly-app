import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

/// A one-time coach mark for the widget-send option in the editor toolbar.
class WidgetShareExplainer extends StatelessWidget {
  const WidgetShareExplainer({required this.onDismiss, super.key});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.lang.shareImageWidgetExplainerTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.lang.shareImageWidgetExplainerBody,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: MyButton(
                          variant: MyButtonVariant.text,
                          onPressed: onDismiss,
                          child: Text(
                            context.lang.shareImageWidgetExplainerDismiss,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.centerRight,
                child: Transform.translate(
                  offset: const Offset(-1.5, 0),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.primary, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
