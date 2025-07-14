import 'package:flutter/material.dart';

class HeadLineComponent extends StatelessWidget {
  const HeadLineComponent(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 17),
      ),
    );
  }
}
