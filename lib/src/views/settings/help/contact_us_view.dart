import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsView extends StatefulWidget {
  const ContactUsView({super.key});

  @override
  State<ContactUsView> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUsView> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _submitFeedback() async {
    final String feedback = _controller.text;

    if (feedback.isEmpty) {
      // Show a message if the text field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your message.')),
      );
      return;
    }

    final user = await getUser();
    if (user == null) return;

    final feedbackFull = "${user.username}\n\n$feedback";

    final response = await http.post(
      Uri.parse('https://twonly.theconnectapp.de/subscribe.twonly.php'),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'feedback': feedbackFull,
      },
    );
    if (!context.mounted) return;

    if (response.statusCode == 200) {
      // Handle successful response
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback submitted successfully!')),
      );
      Navigator.pop(context);
    } else {
      // Handle error response
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit feedback.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsHelpContactUs),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Your Feedback.',
                border: OutlineInputBorder(),
              ),
              maxLines: 10,
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      launchUrl(Uri.parse("https://twonly.eu/support"));
                    },
                    child: Text(
                      'Have you read our FAQ yet?',
                      style: TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _submitFeedback,
                    child: Text('Submit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
