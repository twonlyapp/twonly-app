import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/utils/log.dart';

import 'package:url_launcher/url_launcher.dart';

class BetterText extends StatelessWidget {
  const BetterText({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    // Regular expression to find URLs and domains
    final urlRegExp = RegExp(
      r'(?:(?:https?://|www\.)[^\s]+|(?:[a-zA-Z0-9-]+\.[a-zA-Z]{2,}))',
      caseSensitive: false,
    );

    final spans = <TextSpan>[];
    final matches = urlRegExp.allMatches(text);

    var lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final url = match.group(0);
      spans.add(
        TextSpan(
          text: url,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: Colors.white,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final lUrl =
                  Uri.parse(url!.startsWith('http') ? url : 'http://$url');
              try {
                await launchUrl(lUrl);
              } catch (e) {
                Log.error('Could not launch $e');
              }
            },
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
        ),
      );
    }

    return Text.rich(
      TextSpan(
        children: spans,
      ),
      softWrap: true,
      textAlign: TextAlign.start,
      overflow: TextOverflow.visible,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
      ),
    );
  }
}
