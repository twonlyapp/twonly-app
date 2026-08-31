import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/utils/log.dart';

import 'package:url_launcher/url_launcher.dart';

// Regular expression to find URLs and domains.
final _urlRegExp = RegExp(
  r'''(?:(?:https?://|www\.)(?:[^\s()<>]+|\([^\s()<>]+\))+(?:\([^\s()<>]+\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))|(?:(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})''',
  caseSensitive: false,
);

Future<void> _openUrl(String url) async {
  final lUrl = Uri.parse(url.startsWith('http') ? url : 'http://$url');
  try {
    await launchUrl(lUrl, mode: LaunchMode.externalApplication);
  } catch (e) {
    Log.error('Could not launch $e');
  }
}

class BetterText extends StatefulWidget {
  const BetterText({required this.text, required this.textColor, super.key});
  final String text;
  final Color textColor;

  @override
  State<BetterText> createState() => _BetterTextState();
}

class _BetterTextState extends State<BetterText> {
  /// Link detection only depends on the message text, so the spans and their
  /// gesture recognizers are built once instead of on every rebuild. The
  /// recognizers also need disposing, which the previous per-build version
  /// never did.
  late List<TextSpan> _spans;
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _buildSpans();
  }

  @override
  void didUpdateWidget(BetterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _disposeRecognizers();
      _buildSpans();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _buildSpans() {
    final text = widget.text;
    final spans = <TextSpan>[];
    final matches = _urlRegExp.allMatches(text);

    var lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final url = match.group(0)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () async {
          await _openUrl(url);
        };
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: url,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: Colors.white,
          ),
          recognizer: recognizer,
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

    _spans = spans;
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: _spans,
      ),
      softWrap: true,
      textAlign: TextAlign.start,
      overflow: TextOverflow.visible,
      style: TextStyle(
        color: widget.textColor,
        fontSize: 17,
        decoration: TextDecoration.none,
        fontWeight: FontWeight.normal,
      ),
    );
  }
}
