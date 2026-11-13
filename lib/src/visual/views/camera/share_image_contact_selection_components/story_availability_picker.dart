import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twonly/src/model/story_availability.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_chip.element.dart';

Future<StoryAvailability?> showStoryAvailabilityPicker(
  BuildContext context,
  StoryAvailability current,
) => showModalBottomSheet<StoryAvailability>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _StoryAvailabilityPicker(current: current),
);

class _StoryAvailabilityPicker extends StatefulWidget {
  const _StoryAvailabilityPicker({required this.current});
  final StoryAvailability current;

  @override
  State<_StoryAvailabilityPicker> createState() =>
      _StoryAvailabilityPickerState();
}

class _StoryAvailabilityPickerState extends State<_StoryAvailabilityPicker> {
  late StoryAvailability _availability = widget.current;

  Future<void> _chooseDeadline() async {
    final now = clock.now();
    final maximum = now.add(const Duration(days: 30));
    final previous = _availability.deadline;
    final initial =
        previous != null && previous.isAfter(now) && previous.isBefore(maximum)
        ? previous
        : now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: maximum,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(
      () => _availability = StoryAvailability.until(
        DateTime(date.year, date.month, date.day, time.hour, time.minute),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = clock.now();
    final valid = _availability.isValidAt(now);
    final locale = Localizations.localeOf(context).toString();
    final expiry = _availability.expiresAt(now);
    final label =
        '${DateFormat.yMMMd(locale).format(expiry)} · ${DateFormat.Hm(locale).format(expiry)}';
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.lang.storyAvailableFor,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final days in [1, 3, 7, 30])
                  IntrinsicWidth(
                    child: MyChip(
                      label: Text(
                        days == 1
                            ? context.lang.story24Hours
                            : context.lang.storyDays(days),
                      ),
                      selected: _availability.duration == Duration(days: days),
                      onTap: () => setState(
                        () => _availability = StoryAvailability.duration(
                          Duration(days: days),
                        ),
                      ),
                    ),
                  ),
                IntrinsicWidth(
                  child: MyChip(
                    label: Text(context.lang.storyUntil),
                    selected: _availability.deadline != null,
                    onTap: _chooseDeadline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              valid
                  ? context.lang.storyAvailableUntil(label)
                  : context.lang.storyChooseNewDeadline,
              style: TextStyle(
                color: valid
                    ? context.color.onSurfaceVariant
                    : context.color.error,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: MyButton(
                variant: MyButtonVariant.primaryMiddle,
                onPressed: valid
                    ? () => Navigator.pop(context, _availability)
                    : null,
                child: Text(context.lang.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
