import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/themes/light.dart';

class ThresholdPicker extends StatelessWidget {
  const ThresholdPicker({
    required this.contactCount,
    required this.minThreshold,
    required this.currentThreshold,
    required this.onChanged,
    super.key,
  });

  final int contactCount;
  final int minThreshold;
  final int currentThreshold;
  final ValueChanged<int> onChanged;

  /// Clamps [value] between [minThreshold] and contactCount - 2.
  static int clampThreshold({
    required int value,
    required int minThreshold,
    required int contactCount,
  }) {
    final maxT = (contactCount - 2) < minThreshold
        ? minThreshold
        : (contactCount - 2);
    if (value < minThreshold) return minThreshold;
    if (value > maxT) return maxT;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    if (contactCount == 0) return const SizedBox.shrink();

    final maxT = (contactCount - 2) < minThreshold
        ? minThreshold
        : (contactCount - 2);
    final options = List.generate(
      maxT - minThreshold + 1,
      (i) => minThreshold + i,
    );

    if (options.length == 1) {
      return Text(
        context.lang.passwordlessRecoveryThresholdDesc(options.first),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: context.color.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.lang.passwordlessRecoveryThresholdTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.color.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.color.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.color.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: List.generate(options.length * 2 - 1, (index) {
              if (index.isOdd) {
                return Container(
                  width: 1,
                  height: 40,
                  color: context.color.outlineVariant.withValues(alpha: 0.3),
                );
              }

              final optionIndex = index ~/ 2;
              final value = options[optionIndex];
              final isSelected = value == currentThreshold;

              BorderRadius? borderRadius;
              if (optionIndex == 0) {
                borderRadius = const BorderRadius.horizontal(
                  left: Radius.circular(15),
                );
              } else if (optionIndex == options.length - 1) {
                borderRadius = const BorderRadius.horizontal(
                  right: Radius.circular(15),
                );
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.transparent,
                      borderRadius: borderRadius,
                    ),
                    child: Center(
                      child: Text(
                        '$value',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.black87
                              : context.color.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
