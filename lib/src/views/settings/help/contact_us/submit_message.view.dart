import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/src/utils/misc.dart';

class SubmitMessage extends StatefulWidget {
  const SubmitMessage({super.key, required this.fullMessage});

  final String fullMessage;

  @override
  State<SubmitMessage> createState() => _ContactUsState();
}

class _ContactUsState extends State<SubmitMessage> {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.fullMessage;
  }

  Future<void> _submitFeedback() async {
    final String feedback = _controller.text;
    setState(() {
      isLoading = true;
    });

    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your message.')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://twonly.theconnectapp.de/subscribe.twonly.php'),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'feedback': feedback,
      },
    );
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      // Handle successful response
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.lang.contactUsSuccess)),
      );
      Navigator.pop(context, true);
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
        child: ListView(
          children: [
            Text(
              context.lang.contactUsLastWarning,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: context.lang.contactUsYourMessage,
                border: OutlineInputBorder(),
              ),
              minLines: 5,
              maxLines: 20,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(vertical: 40, horizontal: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: (isLoading) ? null : _submitFeedback,
              child: Text(context.lang.submit),
            ),
          ],
        ),
      ),
    );
  }
}
