import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/json/faq.model.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/settings/help/faq/faq_markdown.view.dart';

class FaqView extends StatefulWidget {
  const FaqView({this.questionId, super.key});

  final String? questionId;

  @override
  State<FaqView> createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> {
  Map<String, FaqCategory>? _faqData;
  late String domain;
  bool _noInternet = false;

  @override
  void initState() {
    super.initState();
    domain = 'https://twonly.eu';
    unawaited(_fetchFAQData());
  }

  Future<void> _fetchFAQData() async {
    final cacheFile = File('${AppEnvironment.cacheDir}/faq.json');
    FaqData? faqData;
    try {
      final response = await http.get(Uri.parse('$domain/faq.json'));

      if (response.statusCode == 200) {
        final jsonData = utf8.decode(response.bodyBytes);
        setState(() {
          faqData = FaqData.fromJson(
            json.decode(jsonData) as Map<String, dynamic>,
          );
          _noInternet = false;
        });
        cacheFile.writeAsStringSync(jsonData);
      } else {
        Log.error('FAQ got ${response.statusCode}');
      }
    } catch (e) {
      Log.error(e);
      setState(() {
        _noInternet = true;
      });
    }
    if (_noInternet && cacheFile.existsSync()) {
      final jsonData = cacheFile.readAsStringSync();
      setState(() {
        faqData = FaqData.fromJson(
          json.decode(jsonData) as Map<String, dynamic>,
        );
        _noInternet = false;
      });
    }

    if (!mounted) return;

    final locale = Localizations.localeOf(context).languageCode;
    _faqData = faqData!.languages[locale] ?? faqData!.languages['en'];

    if (widget.questionId != null && _faqData != null) {
      if (!_navigateToQuestion(widget.questionId!, _faqData!)) {
        final englishData = faqData!.languages['en'];
        if (englishData != null && englishData != _faqData) {
          _navigateToQuestion(widget.questionId!, englishData);
        }
      }
    }
  }

  bool _navigateToQuestion(String questionId, Map<String, FaqCategory> data) {
    for (final category in data.values) {
      for (final question in category.questions) {
        if (question.id == questionId) {
          unawaited(
            context.navPush(
              FaqMarkdownView(
                markdown: question.body,
                title: question.title,
              ),
            ),
          );
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_noInternet) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.lang.settingsHelpFAQ),
        ),
        body: const Center(
          child: Text('Could not load the FAQ.'),
        ),
      );
    }

    if (_faqData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.lang.settingsHelpFAQ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final sortedCategories = _faqData!.entries.toList()
      ..sort((a, b) {
        return b.value.meta.priority.compareTo(a.value.meta.priority);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsHelpFAQ),
      ),
      body: ListView.builder(
        itemCount: sortedCategories.length,
        itemBuilder: (context, index) {
          final categoryData = sortedCategories[index].value;

          return Card(
            child: ExpansionTile(
              title: Text(categoryData.meta.title),
              subtitle: Text(categoryData.meta.desc),
              shape: const RoundedRectangleBorder(),
              backgroundColor: context.color.surfaceContainer,
              collapsedShape: const RoundedRectangleBorder(),
              children: categoryData.questions.map<Widget>((question) {
                return ListTile(
                  title: Text(question.title),
                  onTap: () => context.navPush(
                    FaqMarkdownView(
                      markdown: question.body,
                      title: question.title,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
