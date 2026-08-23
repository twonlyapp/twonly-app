import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';

class ContactLabels extends StatefulWidget {
  const ContactLabels({
    required this.contactId,
    this.fontSize = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.emptyText,
    this.showEmptyText = false,
    this.labels,
    super.key,
  });

  final int contactId;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final String? emptyText;
  final bool showEmptyText;
  final List<Label>? labels;

  @override
  State<ContactLabels> createState() => _ContactLabelsState();
}

class _ContactLabelsState extends State<ContactLabels> {
  List<Label> _labels = [];
  late StreamSubscription<List<Label>> _sub;

  @override
  void initState() {
    super.initState();
    if (widget.labels != null) {
      _labels = widget.labels!;
    } else {
      _sub = twonlyDB.labelsDao.watchContactLabels(widget.contactId).listen((
        labels,
      ) {
        if (mounted) {
          setState(() {
            _labels = labels;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(ContactLabels oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.labels != null && widget.labels != oldWidget.labels) {
      _labels = widget.labels!;
    }
  }

  @override
  void dispose() {
    if (widget.labels == null) _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_labels.isEmpty) {
      if (!widget.showEmptyText && widget.emptyText == null) {
        return const SizedBox.shrink();
      }
      return Text(
        widget.emptyText ?? context.lang.contactLabelsSubtitleEmpty,
        style: TextStyle(
          fontSize: widget.fontSize,
          color: Theme.of(context).disabledColor,
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: _labels.map((label) {
        final bgColor = Color(label.backgroundColor);
        final textColor = Color(label.textColor);

        return Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label.name,
            style: TextStyle(
              fontSize: widget.fontSize,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

Widget? buildContactLabelsSubtitle({
  required int contactId,
  required List<Label> labels,
  Widget? additionalSubtitle,
}) {
  if (additionalSubtitle != null) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        additionalSubtitle,
        if (labels.isNotEmpty) ContactLabels(contactId: contactId),
      ],
    );
  }

  if (labels.isEmpty) {
    return null;
  }

  return ContactLabels(contactId: contactId);
}

class ContactLabelsSubtitleBuilder extends StatelessWidget {
  const ContactLabelsSubtitleBuilder({
    required this.contactId,
    required this.builder,
    this.additionalSubtitle,
    super.key,
  });

  final int contactId;
  final Widget? additionalSubtitle;
  final Widget Function(BuildContext context, Widget? subtitleWidget) builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Label>>(
      stream: twonlyDB.labelsDao.watchContactLabels(contactId),
      builder: (context, snapshot) {
        final labels = snapshot.data ?? [];
        final subtitle = buildContactLabelsSubtitle(
          contactId: contactId,
          labels: labels,
          additionalSubtitle: additionalSubtitle,
        );
        return builder(context, subtitle);
      },
    );
  }
}
