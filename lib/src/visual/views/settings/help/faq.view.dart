// ignore_for_file: avoid_dynamic_calls, inference_failure_on_untyped_parameter

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/settings/help/faq/faq_markdown.view.dart';

class FaqView extends StatefulWidget {
  const FaqView({super.key});

  @override
  State<FaqView> createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> {
  Map<String, dynamic>? _faqData;
  String? _locale;
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
    try {
      final response = await http.get(Uri.parse('$domain/faq.json'));

      if (response.statusCode == 200) {
        final jsonData = utf8.decode(response.bodyBytes);
        setState(() {
          _faqData = json.decode(jsonData) as Map<String, dynamic>?;

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
        _faqData = json.decode(jsonData) as Map<String, dynamic>?;

        _noInternet = false;
      });
    }
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

    final faq = _faqData![_locale ?? 'en'] as Map;
    final sortedCategories = faq.entries.toList()
      ..sort((a, b) {
        final aPriority = (a.value['meta']['priority'] as num? ?? 0).toInt();
        final bPriority = (b.value['meta']['priority'] as num? ?? 0).toInt();
        return bPriority.compareTo(aPriority);
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
              title: Text(categoryData['meta']['title'] as String),
              subtitle: Text(categoryData['meta']['desc'] as String),
              shape: const RoundedRectangleBorder(),
              backgroundColor: context.color.surfaceContainer,
              collapsedShape: const RoundedRectangleBorder(),
              children:
                  categoryData['questions'].map<Widget>((question) {
                        return ListTile(
                          title: Text(question['title'] as String),
                          onTap: () => context.navPush(
                            FaqMarkdownView(
                              markdown: question['body'] as String,
                              title: question['title'] as String,
                            ),
                          ),
                        );
                      }).toList()
                      as List<Widget>,
            ),
          );
        },
      ),
    );
  }
}
