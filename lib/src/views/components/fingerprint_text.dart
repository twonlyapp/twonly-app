import 'package:flutter/material.dart';

class FingerprintText extends StatelessWidget {
  const FingerprintText(this.longString, {super.key});
  final String longString;

  String formatString(String input) {
    final formattedString = StringBuffer();
    var blockCount = 0;

    for (var i = 0; i < input.length; i += 4) {
      final block =
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
    return SelectableText(
      formatString(longString),
      style: const TextStyle(fontSize: 16, color: Colors.black),
      textAlign: TextAlign.center,
    );
  }
}
