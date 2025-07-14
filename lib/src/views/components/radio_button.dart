import 'package:flutter/material.dart';

class RadioButton<T> extends StatelessWidget {
  const RadioButton({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
    super.key,
  });
  final T value;
  final T? groupValue;
  final String label;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<T>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () =>
                onChanged(value), // Call onChanged when the text is tapped
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
