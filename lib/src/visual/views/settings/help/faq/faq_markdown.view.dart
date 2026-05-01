import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';

class FaqMarkdownView extends StatelessWidget {
  const FaqMarkdownView({
    required this.markdown,
    required this.title,
    super.key,
  });

  final String title;
  final String markdown;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(substringBy(title, 30)),
      ),
      body: Markdown(
        data: markdown,
        padding: const EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: 40,
        ),
      ),
    );
  }
}
