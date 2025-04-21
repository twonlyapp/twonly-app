import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twonly/src/views/camera/image_editor/layers/filter_layer.dart';

class DateTimeFilter extends StatelessWidget {
  const DateTimeFilter({super.key, this.color = Colors.white});

  final Color color;

  @override
  Widget build(BuildContext context) {
    String currentTime = DateFormat('HH:mm').format(DateTime.now());
    String currentDate = DateFormat('dd.MM.yyyy').format(DateTime.now());
    return FilterSceleton(
      child: Positioned(
        bottom: 80,
        left: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilterText(currentTime, color: color),
            FilterText(currentDate, color: color),
          ],
        ),
      ),
    );
  }
}
