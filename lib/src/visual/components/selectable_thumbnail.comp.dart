import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

class SelectableThumbnailComp extends StatelessWidget {
  const SelectableThumbnailComp({
    required this.child,
    required this.isSelected,
    this.selectionMode = true,
    super.key,
  });

  final Widget child;
  final bool isSelected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? context.color.primary : Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: context.color.shadow.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: EdgeInsets.all(isSelected ? 4 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            isSelected ? 12 : 0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (selectionMode)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.color.primary
                        : context.color.scrim.withValues(alpha: 0.38),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.color.onSurface,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: context.color.onPrimary,
                        )
                      : const SizedBox(width: 14, height: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
