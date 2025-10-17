// ignore_for_file: avoid_dynamic_calls, inference_failure_on_untyped_parameter

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:url_launcher/url_launcher.dart';

class FaqView extends StatefulWidget {
  const FaqView({super.key});

  @override
  State<FaqView> createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> {
  Map<String, dynamic>? _faqData;
  String? _locale;
  late String domain;
  bool noInternet = false;

  @override
  void initState() {
    super.initState();
    domain = 'https://twonly.eu';
    unawaited(_fetchFAQData());
  }

  Future<void> _fetchFAQData() async {
    try {
      final response = await http.get(Uri.parse('$domain/faq.json'));

      if (response.statusCode == 200) {
        setState(() {
          _faqData = json.decode(utf8.decode(response.bodyBytes))
              as Map<String, dynamic>?;
          noInternet = false;
        });
      } else {
        Log.error('FAQ got ${response.statusCode}');
      }
    } catch (e) {
      Log.error(e);
      setState(() {
        noInternet = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (noInternet) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsHelpFAQ),
      ),
      body: ListView.builder(
        itemCount: faq.keys.length,
        itemBuilder: (context, index) {
          final category = faq.keys.elementAt(index);
          final categoryData = faq[category];

          return Card(
            child: ExpansionTile(
              title: Text(categoryData['meta']['title'] as String),
              subtitle: Text(categoryData['meta']['desc'] as String),
              children: categoryData['questions'].map<Widget>((question) {
                return ListTile(
                  title: Text(question['title'] as String),
                  onTap: () => _launchURL(question['path'] as String),
                );
              }).toList() as List<Widget>,
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchURL(String path) async {
    try {
      await launchUrl(Uri.parse('$domain$path'));
    } catch (e) {
      Log.error('Could not launch $e');
    }
  }
}
