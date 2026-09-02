import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_card.element.dart';

/// A recovery option, tinted red until it is actually set up.
class RecoveryCard extends StatelessWidget {
  const RecoveryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
    this.isEnabled = false,
  });
  final dynamic icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return MyCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      accentColor: isEnabled ? context.color.primary : Colors.red,
    );
  }
}
