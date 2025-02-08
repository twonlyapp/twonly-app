import 'package:flutter/material.dart';

class FormattedStringWidget extends StatelessWidget {
  final String longString;

  const FormattedStringWidget(this.longString, {super.key});

  String formatString(String input) {
    StringBuffer formattedString = StringBuffer();
    int blockCount = 0;

    for (int i = 0; i < input.length; i += 4) {
      String block =
          input.substring(i, i + 4 > input.length ? input.length : i + 4);
      formattedString.write(block);
      blockCount++;

      if (blockCount == 5) {
        formattedString.writeln();
        blockCount = 0;
      } else {
        formattedString.write(' ');
      }
    }

    return formattedString.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatString(longString),
      style: TextStyle(fontSize: 18, color: Colors.black),
      textAlign: TextAlign.center,
    );
  }
}
