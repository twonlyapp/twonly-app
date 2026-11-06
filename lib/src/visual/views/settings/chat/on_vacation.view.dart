import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:twonly/core/bridge.dart' show VacationWindow;
import 'package:twonly/core/bridge/groups.dart' as rust_groups;
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/pro_badge.element.dart';
import 'package:twonly/src/visual/views/settings/components/settings_layout.dart';

/// "On Vacation": freezes every streak above four flames for a few days and
/// tells those friends. Rust decides which chats qualify and enforces the
/// plan; this view only picks the icon and the length.
class OnVacationView extends StatefulWidget {
  const OnVacationView({super.key});

  @override
  State<OnVacationView> createState() => _OnVacationViewState();
}

class _OnVacationViewState extends State<OnVacationView> {
  final rust_groups.VacationOptions _options = rust_groups.vacationOptions();
  late String _icon = _options.icons.first;
  late int _days = _defaultDays.clamp(_options.minDays, _options.maxDays);
  VacationWindow? _vacation;
  int? _candidates;
  bool _loading = true;
  bool _busy = false;

  static const _defaultDays = 5;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    VacationWindow? vacation;
    int? candidates;
    try {
      vacation = await rust_groups.ownVacation();
      candidates = await rust_groups.vacationCandidateCount();
    } catch (error, stackTrace) {
      Log.warn('Could not load the vacation state.', error, stackTrace);
    }
    if (!mounted) return;
    setState(() {
      _vacation = vacation;
      _candidates = candidates;
      _loading = false;
    });
  }

  bool get _allowed => isUserAllowed(
    planFromString(userService.currentUser.subscriptionPlan),
    PremiumFeatures.OnVacation,
  );

  String _formatDay(DateTime day) =>
      DateFormat.MMMEd(Localizations.localeOf(context).toString()).format(day);

  Future<void> _start() async {
    if (_busy) return;
    if (!_allowed) {
      await context.push(Routes.settingsSubscription);
      return;
    }
    setState(() => _busy = true);
    int? frozen;
    try {
      frozen = await rust_groups.startVacation(days: _days, icon: _icon);
    } catch (error, stackTrace) {
      Log.warn('Could not start the vacation.', error, stackTrace);
      if (mounted) showSnackbar(context, context.lang.onVacationFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (frozen == 0) {
      showSnackbar(
        context,
        context.lang.onVacationNothingToFreeze(_options.minFlames - 1),
        level: SnackbarLevel.info,
      );
    } else if (frozen != null) {
      showSnackbar(
        context,
        context.lang.onVacationStarted(frozen),
        level: SnackbarLevel.success,
      );
    }
    await _load();
  }

  Future<void> _end() async {
    if (_busy) return;
    final confirmed = await showAlertDialog(
      context,
      context.lang.onVacationEndConfirmTitle,
      context.lang.onVacationEndConfirmBody,
      customOk: context.lang.onVacationEnd,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await rust_groups.endVacation();
    } catch (error, stackTrace) {
      Log.warn('Could not end the vacation.', error, stackTrace);
      if (mounted) showSnackbar(context, context.lang.onVacationFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final vacation = _vacation;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(lang.settingsOnVacationTitle)),
            const SizedBox(width: 8),
            const ProBadge(),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SettingsList(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: vacation != null
                  ? _active(context, vacation)
                  : _picker(context),
            ),
    );
  }

  List<Widget> _active(BuildContext context, VacationWindow vacation) {
    final lang = context.lang;
    // The window ends at the midnight after the last vacation day.
    final lastDay = DateTime.fromMillisecondsSinceEpoch(
      vacation.until * 1000 - 1,
    );
    return [
      SizedBox(
        height: 96,
        child: EmojiAnimationComp(emoji: vacation.icon),
      ),
      const SizedBox(height: 16),
      Text(
        lang.onVacationActiveUntil(_formatDay(lastDay)),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      _Explanation(lang.onVacationExplanation(_options.minFlames - 1)),
      const SizedBox(height: 24),
      Center(
        child: MyButton(
          variant: MyButtonVariant.errorMiddle,
          onPressed: _busy ? null : _end,
          child: Text(lang.onVacationEnd),
        ),
      ),
    ];
  }

  List<Widget> _picker(BuildContext context) {
    final lang = context.lang;
    final today = clock.now();
    final countsAgain = DateTime(today.year, today.month, today.day + _days);
    final candidates = _candidates;
    return [
      _Explanation(lang.onVacationExplanation(_options.minFlames - 1)),
      const SizedBox(height: 24),
      _Label(lang.onVacationIcon),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final icon in _options.icons)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _IconChoice(
                icon: icon,
                selected: icon == _icon,
                onTap: () => setState(() => _icon = icon),
              ),
            ),
        ],
      ),
      const SizedBox(height: 24),
      _Label(lang.onVacationDuration),
      Text(
        lang.onVacationDays(_days),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      _DayDots(
        firstDay: DateTime(today.year, today.month, today.day),
        days: _days,
        minDays: _options.minDays,
        maxDays: _options.maxDays,
        onChanged: (days) => setState(() => _days = days),
      ),
      const SizedBox(height: 12),
      _Explanation(lang.onVacationCountsAgain(_formatDay(countsAgain))),
      if (candidates != null) ...[
        const SizedBox(height: 8),
        _Explanation(
          lang.onVacationAffectedChats(candidates, _options.minFlames - 1),
        ),
      ],
      const SizedBox(height: 24),
      Center(
        child: MyButton(
          variant: MyButtonVariant.primaryMiddle,
          onPressed: _busy || (_allowed && candidates == 0) ? null : _start,
          child: Text(lang.onVacationStart),
        ),
      ),
    ];
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: context.color.onSurfaceVariant, fontSize: 13),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: icon,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? context.color.primary : Colors.transparent,
              width: 2,
            ),
            color: selected
                ? context.color.primary.withValues(alpha: 0.08)
                : context.color.surfaceContainerHighest,
          ),
          child: EmojiAnimationComp(emoji: icon),
        ),
      ),
    );
  }
}

/// One dot per possible vacation day, starting today, labelled with its
/// weekday. The days on vacation are filled and joined; the first [minDays]
/// always are. Tapping a dot or dragging along the row picks the length.
class _DayDots extends StatelessWidget {
  const _DayDots({
    required this.firstDay,
    required this.days,
    required this.minDays,
    required this.maxDays,
    required this.onChanged,
  });

  final DateTime firstDay;
  final int days;
  final int minDays;
  final int maxDays;
  final ValueChanged<int> onChanged;

  static const _dot = 32.0;

  DateTime _dateOf(int day) =>
      DateTime(firstDay.year, firstDay.month, firstDay.day + day - 1);

  void _pick(int day) {
    final clamped = day.clamp(minDays, maxDays);
    if (clamped != days) onChanged(clamped);
  }

  void _pickAt(double dx, double width) {
    final slot = width / maxDays;
    _pick((dx / slot).floor() + 1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.color;
    final locale = Localizations.localeOf(context).toString();
    final weekday = DateFormat.E(locale);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final slot = width / maxDays;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) =>
              _pickAt(details.localPosition.dx, width),
          onHorizontalDragUpdate: (details) =>
              _pickAt(details.localPosition.dx, width),
          child: Stack(
            children: [
              // The line joining the chosen days, behind the dots.
              Positioned(
                left: slot / 2,
                right: slot / 2,
                top: _dot / 2 - 2,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                left: slot / 2,
                width: slot * (days - 1),
                top: _dot / 2 - 2,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var day = 1; day <= maxDays; day++)
                    SizedBox(
                      width: slot,
                      child: Semantics(
                        button: true,
                        selected: day == days,
                        label: weekday.format(_dateOf(day)),
                        child: InkWell(
                          key: ValueKey('vacationDay$day'),
                          customBorder: const CircleBorder(),
                          onTap: () => _pick(day),
                          child: _DayDot(
                            day: day,
                            weekday: weekday.format(_dateOf(day)),
                            chosen: day <= days,
                            last: day == days,
                            size: _dot,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.day,
    required this.weekday,
    required this.chosen,
    required this.last,
    required this.size,
  });

  final int day;
  final String weekday;
  final bool chosen;
  final bool last;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: chosen ? colors.primary : colors.surfaceContainerHighest,
            border: last
                ? Border.all(color: colors.primaryContainer, width: 3)
                : null,
          ),
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: last ? FontWeight.bold : FontWeight.w500,
              color: chosen ? colors.onPrimary : colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          // "Do." reads better without its abbreviation dot under a dot.
          weekday.replaceAll('.', ''),
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            fontSize: 11,
            color: chosen ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
