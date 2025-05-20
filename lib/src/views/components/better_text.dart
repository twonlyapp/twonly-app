import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

class BetterText extends StatelessWidget {
  final String text;

  const BetterText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    // Regular expression to find URLs and domains
    final RegExp urlRegExp = RegExp(
      r'(?:(?:https?://|www\.)[^\s]+|(?:[a-zA-Z0-9-]+\.[a-zA-Z]{2,}))',
      caseSensitive: false,
      multiLine: false,
    );

    final List<TextSpan> spans = [];
    final Iterable<RegExpMatch> matches = urlRegExp.allMatches(text);

    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final String? url = match.group(0);
      spans.add(TextSpan(
        text: url,
        style: TextStyle(color: Colors.blue),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final lUrl =
                Uri.parse(url!.startsWith('http') ? url : 'http://$url');
            try {
              await launchUrl(lUrl);
            } catch (e) {
              Logger("launchUrl").shout("Could not launch $e");
            }
          },
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return SelectableText.rich(
      TextSpan(
        children: spans,
      ),
      style: TextStyle(
        color: Colors.white,
        fontSize: 17,
      ),
    );
  }
}
