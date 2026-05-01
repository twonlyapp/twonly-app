import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

class SetupSwitchCard extends StatelessWidget {
  const SetupSwitchCard({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.expandedChild,
    this.openIfNot = false,
    super.key,
  });

  final bool value;
  final bool openIfNot;
  final ValueChanged<bool> onChanged;
  final String title;
  final Widget expandedChild;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            value: value,
            onChanged: onChanged,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            tileColor: context.color.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            curve: Curves.bounceInOut,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: double.infinity,
              child: (value && !openIfNot) || (!value && openIfNot)
                  ? Container(
                      decoration: BoxDecoration(
                        color: context.color.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: expandedChild,
                      ),
                    )
                  : const SizedBox(height: 0),
            ),
          ),
        ],
      ),
    );
  }
}
