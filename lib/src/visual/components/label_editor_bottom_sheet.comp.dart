import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/custom_color_picker_dialog.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class LabelEditorBottomSheet extends StatefulWidget {
  const LabelEditorBottomSheet({
    this.label,
    super.key,
  });

  final Label? label;

  @override
  State<LabelEditorBottomSheet> createState() => _LabelEditorBottomSheetState();
}

class _LabelEditorBottomSheetState extends State<LabelEditorBottomSheet> {
  late TextEditingController _nameController;
  late int _selectedBgColor;
  late int _selectedTextColor;

  static const List<int> defaultBgColors = [
    0xFFE57373, // Red
    0xFFF06292, // Pink
    0xFFBA68C8, // Purple
    0xFF7986CB, // Indigo
    0xFF64B5F6, // Blue
    0xFF4DD0E1, // Cyan
    0xFF4DB6AC, // Teal
    0xFF81C784, // Green
    0xFFFFB74D, // Amber
    0xFFFF8A65, // Deep Orange
    0xFF90A4AE, // Blue Grey
    0xFF424242, // Dark Grey
  ];

  static const List<int> defaultTextColors = [
    0xFFFFFFFF, // White
    0xFF121212, // Dark/Black
    0xFF1B263B, // Deep Navy
    0xFF8B0000, // Dark Red
    0xFF004D40, // Dark Teal
    0xFF4A148C, // Dark Purple
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.label?.name ?? '');
    _selectedBgColor = widget.label?.backgroundColor ?? defaultBgColors[4];
    _selectedTextColor = widget.label?.textColor ?? defaultTextColors[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomColor({required bool isBgColor}) async {
    final initial = isBgColor ? Color(_selectedBgColor) : Color(_selectedTextColor);
    final pickedColorInt = await showDialog<int>(
      context: context,
      builder: (context) => CustomColorPickerDialog(initialColor: initial),
    );

    if (pickedColorInt != null && mounted) {
      setState(() {
        if (isBgColor) {
          _selectedBgColor = pickedColorInt;
        } else {
          _selectedTextColor = pickedColorInt;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.label != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag indicator handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isEditing ? context.lang.editLabel : context.lang.createLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Interactive Inline Label Badge
              Center(
                child: IntrinsicWidth(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(_selectedBgColor),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      child: TextField(
                        controller: _nameController,
                        autofocus: true,
                        maxLength: 8,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(
                          color: Color(_selectedTextColor),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: context.lang.labelNameHint,
                          hintStyle: TextStyle(
                            color: Color(_selectedTextColor).withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          counterText: '',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Background Color Section
              Text(
                context.lang.labelBackgroundColor,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  ...defaultBgColors.map((colorValue) {
                    final selected = _selectedBgColor == colorValue;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedBgColor = colorValue;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(colorValue),
                          shape: BoxShape.circle,
                        ),
                        child: selected
                            ? Icon(
                                Icons.check,
                                size: 18,
                                color: Color(colorValue).computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              )
                            : null,
                      ),
                    );
                  }),
                  // Custom Color Picker Button
                  GestureDetector(
                    onTap: () => _pickCustomColor(isBgColor: true),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.red,
                            Colors.yellow,
                            Colors.green,
                            Colors.cyan,
                            Colors.blue,
                            Colors.purple,
                            Colors.red,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.colorize,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Text Color Section
              Text(
                context.lang.labelTextColor,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  ...defaultTextColors.map((colorValue) {
                    final selected = _selectedTextColor == colorValue;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTextColor = colorValue;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(colorValue),
                          shape: BoxShape.circle,
                        ),
                        child: selected
                            ? Icon(
                                Icons.check,
                                size: 18,
                                color: Color(colorValue).computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              )
                            : null,
                      ),
                    );
                  }),
                  // Custom Color Picker Button for Text
                  GestureDetector(
                    onTap: () => _pickCustomColor(isBgColor: false),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.red,
                            Colors.yellow,
                            Colors.green,
                            Colors.cyan,
                            Colors.blue,
                            Colors.purple,
                            Colors.red,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.colorize,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: MyButton(
                      variant: MyButtonVariant.text,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.lang.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MyButton(
                      variant: MyButtonVariant.primaryMiddle,
                      onPressed: () {
                        final name = _nameController.text.trim();
                        if (name.isNotEmpty) {
                          Navigator.of(context).pop({
                            'name': name,
                            'backgroundColor': _selectedBgColor,
                            'textColor': _selectedTextColor,
                          });
                        }
                      },
                      child: Text(context.lang.ok),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
