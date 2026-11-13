import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_chip.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';

List<(int, String)> chatDeletionTimeOptions(BuildContext context) => [
  (
    const Duration(hours: 1).inMilliseconds,
    context.lang.chatDeletionPresetHour,
  ),
  (const Duration(days: 1).inMilliseconds, context.lang.chatDeletionPresetDay),
  (const Duration(days: 7).inMilliseconds, context.lang.chatDeletionPresetWeek),
  (
    const Duration(days: 30).inMilliseconds,
    context.lang.chatDeletionPresetMonth,
  ),
  (
    const Duration(days: 365).inMilliseconds,
    context.lang.chatDeletionPresetYear,
  ),
];

enum _TimerUnit {
  hours(Duration.millisecondsPerHour),
  days(Duration.millisecondsPerDay),
  weeks(Duration.millisecondsPerDay * 7),
  months(Duration.millisecondsPerDay * 30);

  const _TimerUnit(this.milliseconds);
  final int milliseconds;

  String label(BuildContext context) => switch (this) {
    hours => context.lang.chatDeletionUnitHours,
    days => context.lang.chatDeletionUnitDays,
    weeks => context.lang.chatDeletionUnitWeeks,
    months => context.lang.chatDeletionUnitMonths,
  };
}

class ChatDeletionTimeSheet extends StatefulWidget {
  const ChatDeletionTimeSheet({required this.initialMilliseconds, super.key});

  final int initialMilliseconds;

  @override
  State<ChatDeletionTimeSheet> createState() => _ChatDeletionTimeSheetState();
}

class _ChatDeletionTimeSheetState extends State<ChatDeletionTimeSheet> {
  late final TextEditingController _controller;
  late _TimerUnit _unit;
  late int _selected;
  bool? _custom;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialMilliseconds;
    _unit = _TimerUnit.values.reversed.firstWhere(
      (unit) => _selected > 0 && _selected % unit.milliseconds == 0,
      orElse: () => _TimerUnit.hours,
    );
    _controller = TextEditingController(
      text: _selected % _unit.milliseconds == 0
          ? '${_selected ~/ _unit.milliseconds}'
          : '${_selected / _unit.milliseconds}',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _custom ??= !chatDeletionTimeOptions(context).any((t) => t.$1 == _selected);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_custom!) {
      final amount = double.tryParse(_controller.text.replaceAll(',', '.'));
      final milliseconds = amount == null ? null : amount * _unit.milliseconds;
      if (milliseconds == null ||
          !milliseconds.isFinite ||
          milliseconds < Duration.millisecondsPerMinute ||
          milliseconds > const Duration(days: 365).inMilliseconds) {
        setState(() => _showError = true);
        return;
      }
      _selected = milliseconds.round();
    }
    Navigator.pop(context, _selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.color;
    final textTheme = Theme.of(context).textTheme;
    final options = chatDeletionTimeOptions(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  context.lang.deleteChatAfter,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Two columns leave room for larger accessibility text.
                  final columns =
                      MediaQuery.textScalerOf(context).scale(14) > 18 ? 2 : 3;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 8) / columns;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: [
                      for (final option in options)
                        SizedBox(
                          width: width,
                          child: MyChip(
                            label: Text(option.$2, maxLines: 1),
                            selected: !_custom! && _selected == option.$1,
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _selected = option.$1;
                                _custom = false;
                                _showError = false;
                              });
                            },
                          ),
                        ),
                      SizedBox(
                        width: width,
                        child: MyChip(
                          label: Text(context.lang.chatDeletionCustomChoice),
                          selected: _custom!,
                          onTap: () => setState(() => _custom = true),
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (_custom!) ...[
                const SizedBox(height: 24),
                Text(
                  context.lang.chatDeletionDuration,
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                MyInput(
                  controller: _controller,
                  dense: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                  ],
                  onChanged: (_) => setState(() => _showError = false),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 8,
                  children: [
                    for (final unit in _TimerUnit.values)
                      IntrinsicWidth(
                        child: MyChip(
                          label: Text(unit.label(context)),
                          selected: _unit == unit,
                          onTap: () => setState(() {
                            _unit = unit;
                            _showError = false;
                          }),
                        ),
                      ),
                  ],
                ),
                if (_showError) ...[
                  const SizedBox(height: 12),
                  Text(
                    context.lang.chatDeletionDurationInvalid,
                    style: textTheme.bodySmall?.copyWith(color: colors.error),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              OverflowBar(
                alignment: MainAxisAlignment.center,
                spacing: 12,
                overflowSpacing: 8,
                overflowAlignment: OverflowBarAlignment.center,
                children: [
                  MyButton(
                    variant: MyButtonVariant.secondaryMiddle,
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.lang.cancel),
                  ),
                  MyButton(
                    variant: MyButtonVariant.primaryMiddle,
                    onPressed: _save,
                    child: Text(context.lang.save),
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
