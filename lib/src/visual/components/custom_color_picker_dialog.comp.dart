import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class CustomColorPickerDialog extends StatefulWidget {
  const CustomColorPickerDialog({
    required this.initialColor,
    super.key,
  });

  final Color initialColor;

  @override
  State<CustomColorPickerDialog> createState() =>
      _CustomColorPickerDialogState();
}

class _CustomColorPickerDialogState extends State<CustomColorPickerDialog> {
  late HSVColor _hsvColor;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _hsvColor.toColor();

    return AlertDialog(
      title: Text(context.lang.customColor),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color preview box
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Hue Slider
            Text(
              context.lang.hue,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _hsvColor.hue,
              max: 360,
              activeColor: HSVColor.fromAHSV(1, _hsvColor.hue, 1, 1).toColor(),
              onChanged: (val) {
                setState(() {
                  _hsvColor = _hsvColor.withHue(val);
                });
              },
            ),
            // Saturation Slider
            Text(
              context.lang.saturation,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _hsvColor.saturation,
              onChanged: (val) {
                setState(() {
                  _hsvColor = _hsvColor.withSaturation(val);
                });
              },
            ),
            // Brightness / Value Slider
            Text(
              context.lang.brightness,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _hsvColor.value,
              onChanged: (val) {
                setState(() {
                  _hsvColor = _hsvColor.withValue(val);
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: MyButton(
                variant: MyButtonVariant.text,
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.lang.cancel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MyButton(
                variant: MyButtonVariant.primaryMiddle,
                onPressed: () =>
                    Navigator.of(context).pop(currentColor.toARGB32()),
                child: Text(context.lang.ok),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
