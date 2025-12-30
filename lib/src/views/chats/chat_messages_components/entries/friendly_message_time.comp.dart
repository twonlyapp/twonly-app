import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';

class FriendlyMessageTime extends StatelessWidget {
  const FriendlyMessageTime({required this.message, super.key});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentGeometry.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Row(
          children: [
            if (message.modifiedAt != null)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: SizedBox(
                  height: 10,
                  child: FaIcon(
                    FontAwesomeIcons.pencil,
                    color: Colors.white.withAlpha(150),
                    size: 10,
                  ),
                ),
              ),
            Text(
              friendlyTime(
                context,
                (message.modifiedAt != null)
                    ? message.modifiedAt!
                    : message.createdAt,
              ),
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withAlpha(150),
                decoration: TextDecoration.none,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String friendlyTime(BuildContext context, DateTime dt) {
  final now = clock.now();
  final diff = now.difference(dt);

  if (diff.inMinutes >= 0 && diff.inMinutes < 60) {
    final minutes = diff.inMinutes == 0 ? 1 : diff.inMinutes;
    if (minutes <= 1) {
      return context.lang.now;
    }
    return '$minutes ${context.lang.minutesShort}';
  }

  // Determine 24h vs 12h from system/local settings
  final use24Hour = MediaQuery.of(context).alwaysUse24HourFormat;

  if (!use24Hour) {
    // 12-hour format with locale-aware AM/PM
    final format = DateFormat.jm(Localizations.localeOf(context).toString());
    return format.format(dt);
  } else {
    // 24-hour HH:mm, locale-aware
    final format = DateFormat.Hm(Localizations.localeOf(context).toString());
    return format.format(dt);
  }
}
