import 'package:flutter/material.dart';

class HeadLineComponent extends StatelessWidget {
  final String text;

  const HeadLineComponent(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 10),
      child: Text(
        text,
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
