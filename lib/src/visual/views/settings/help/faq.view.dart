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
  bool _noInternet = false;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchFAQData());
  }

  Future<void> _fetchFAQData() async {
    final cacheFile = File('${AppEnvironment.cacheDir}/faq.json');
    FaqData? faqData;
    try {
      final response = await http
          .get(Uri.parse('https://twonly.eu/faq.json'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw HttpException('FAQ got ${response.statusCode}');
      }
      final jsonData = utf8.decode(response.bodyBytes);
      final parsed = FaqData.fromJson(
        json.decode(jsonData) as Map<String, dynamic>,
      );
      if (parsed.languages.isEmpty ||
          (mounted &&
              parsed.languages[Localizations.localeOf(context).languageCode] ==
                  null &&
              parsed.languages['en'] == null)) {
        throw const FormatException('FAQ has no usable language');
      }
      faqData = parsed;
      // A cache write failure must not discard a successful response.
      try {
        cacheFile.writeAsStringSync(jsonData);
      } catch (error, stackTrace) {
        Log.warn(
          'Could not cache the FAQ',
          error,
          stackTrace,
        );
      }
    } catch (error, stackTrace) {
      Log.warn('Could not fetch the FAQ', error, stackTrace);
    }
    if (faqData == null) {
      try {
        if (cacheFile.existsSync()) {
          faqData = FaqData.fromJson(
            json.decode(cacheFile.readAsStringSync()) as Map<String, dynamic>,
          );
        }
      } catch (error, stackTrace) {
        Log.warn(
          'Could not read the cached FAQ',
          error,
          stackTrace,
        );
      }
    }

    if (!mounted) return;
    final locale = Localizations.localeOf(context).languageCode;
    final data = faqData?.languages[locale] ?? faqData?.languages['en'];
    setState(() {
      _faqData = data;
      _noInternet = data == null;
    });

    final questionId = widget.questionId;
    if (questionId != null && data != null) {
      if (!_navigateToQuestion(questionId, data)) {
        final englishData = faqData?.languages['en'];
        if (englishData != null && englishData != data) {
          _navigateToQuestion(questionId, englishData);
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
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load the FAQ.'),
              TextButton(
                onPressed: () {
                  setState(() => _noInternet = false);
                  unawaited(_fetchFAQData());
                },
                child: Text(context.lang.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_faqData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.lang.settingsHelpFAQ),
        ),
        body: const Center(child: CircularProgressIndicator.adaptive()),
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
