import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/intent/links.intent.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/mentions.dart';
import 'package:twonly/src/visual/components/mention_decoration.dart';
import 'package:twonly/src/visual/components/mention_style.dart';
import 'package:twonly/src/visual/components/mention_text.dart';
import 'package:url_launcher/url_launcher.dart';

// Regular expression to find URLs and domains.
final _urlRegExp = RegExp(
  r'''(?:(?:https?://|www\.)(?:[^\s()<>]+|\([^\s()<>]+\))+(?:\([^\s()<>]+\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))|(?:(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})''',
  caseSensitive: false,
);

class BetterText extends StatelessWidget {
  const BetterText({
    required this.text,
    required this.textColor,
    this.contactsById,
    super.key,
  });
  final String text;
  final Color textColor;
  final Map<int, Contact>? contactsById;

  @override
  Widget build(BuildContext context) => MentionNames(
    text: text,
    contactsById: contactsById,
    builder: (context, name) => _BetterTextContent(
      text: text,
      textColor: textColor,
      displayName: name,
      resolvedText: resolveMentions(text, name),
    ),
  );
}

class _BetterTextContent extends StatefulWidget {
  const _BetterTextContent({
    required this.text,
    required this.textColor,
    required this.displayName,
    required this.resolvedText,
  });
  final String text;
  final Color textColor;
  final String Function(int) displayName;
  final String resolvedText;

  @override
  State<_BetterTextContent> createState() => _BetterTextState();
}

class _BetterTextState extends State<_BetterTextContent> {
  /// Link detection only depends on the message text, so the spans and their
  /// gesture recognizers are built once instead of on every rebuild. The
  /// recognizers also need disposing, which the previous per-build version
  /// never did.
  late List<TextSpan> _spans;
  late List<TextSelection> _mentionSelections;
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _buildSpans();
  }

  @override
  void didUpdateWidget(_BetterTextContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.resolvedText != widget.resolvedText ||
        oldWidget.textColor != widget.textColor) {
      _disposeRecognizers();
      _buildSpans();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _disposeRecognizers();
    _buildSpans();
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

  /// twonly's own links (profile, QR and passwordless recovery links) are
  /// handled in the app instead of being handed to the browser, which would
  /// only land on a page that cannot do anything with the fragment.
  Future<void> _openUrl(String url) async {
    final lUrl = Uri.parse(url.startsWith('http') ? url : 'http://$url');
    if (mounted && await handleIntentUrl(context, lUrl)) return;
    try {
      await launchUrl(lUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      Log.error('Could not launch $e');
    }
  }

  void _buildSpans() {
    final text = widget.text;
    final spans = <TextSpan>[];
    final selections = <TextSelection>[];
    var offset = 0;
    for (final part in parseMentions(text)) {
      final id = part.userId;
      if (id != null) {
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            final isSelf =
                locator.isRegistered<UserService>() &&
                userService.isUserCreated &&
                userService.currentUser.userId == id;
            context.push(
              isSelf ? Routes.settingsProfile : Routes.profileContact(id),
            );
          };
        _recognizers.add(recognizer);
        final label = '@${widget.displayName(id)}';
        selections.add(
          TextSelection(
            baseOffset: offset,
            extentOffset: offset + label.length,
          ),
        );
        offset += label.length;
        spans.add(
          TextSpan(
            text: label,
            style: mentionTextStyle.copyWith(color: widget.textColor),
            recognizer: recognizer,
          ),
        );
        continue;
      }
      var lastMatchEnd = 0;
      for (final match in _urlRegExp.allMatches(part.text)) {
        if (match.start > lastMatchEnd) {
          spans.add(
            TextSpan(text: part.text.substring(lastMatchEnd, match.start)),
          );
        }
        final url = match.group(0)!;
        final recognizer = TapGestureRecognizer()..onTap = () => _openUrl(url);
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: url,
            style: TextStyle(
              decoration: TextDecoration.underline,
              decorationColor: widget.textColor,
            ),
            recognizer: recognizer,
          ),
        );
        lastMatchEnd = match.end;
      }
      if (lastMatchEnd < part.text.length) {
        spans.add(TextSpan(text: part.text.substring(lastMatchEnd)));
      }
      offset += part.text.length;
    }

    _spans = spans;
    _mentionSelections = selections;
  }

  @override
  Widget build(BuildContext context) {
    return MentionBackground(
      selections: _mentionSelections,
      child: Text.rich(
        TextSpan(children: _spans),
        softWrap: true,
        textAlign: TextAlign.start,
        overflow: TextOverflow.visible,
        style: TextStyle(
          color: widget.textColor,
          fontSize: 17,
          decoration: TextDecoration.none,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}
