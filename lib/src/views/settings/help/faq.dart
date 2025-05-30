import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:url_launcher/url_launcher.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  Map<String, dynamic>? _faqData;
  String? _locale;
  late String domain;
  bool noInternet = false;

  @override
  void initState() {
    super.initState();
    domain = "https://twonly.eu";
    _fetchFAQData();
  }

  Future<void> _fetchFAQData() async {
    try {
      final response = await http.get(Uri.parse("$domain/faq.json"));

      if (response.statusCode == 200) {
        _locale = Localizations.localeOf(context).languageCode;
        setState(() {
          _faqData = json.decode(utf8.decode(response.bodyBytes));
          noInternet = false;
        });
      } else {
        Logger("faq.dart").shout("FAQ got ${response.statusCode}");
        // throw Exception('Failed to load FAQ data');
      }
    } catch (e) {
      Logger("faq.dart").shout(e);
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
        body: Center(
          child: Text("Could not load the FAQ."),
        ),
      );
    }

    if (_faqData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.lang.settingsHelpFAQ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final faq = _faqData![_locale ?? 'en'];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsHelpFAQ),
      ),
      body: ListView.builder(
        itemCount: faq.keys.length,
        itemBuilder: (context, index) {
          String category = faq.keys.elementAt(index);
          var categoryData = faq[category];

          return Card(
            child: ExpansionTile(
              title: Text(categoryData['meta']['title']),
              subtitle: Text(categoryData['meta']['desc']),
              children: categoryData['questions'].map<Widget>((question) {
                return ListTile(
                  title: Text(question['title']),
                  onTap: () => _launchURL(question['path']),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  void _launchURL(String path) async {
    try {
      await launchUrl(Uri.parse("$domain$path"));
    } catch (e) {
      Logger("launchUrl").shout("Could not launch $e");
    }
  }
}
