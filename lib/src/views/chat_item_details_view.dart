import 'package:flutter/material.dart';

class AlignedTextBox extends StatelessWidget {
  const AlignedTextBox({super.key, required this.text, required this.right});
  final String text;
  final bool right;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width *
                0.8, // Maximum 80% of the screen width
          ),
          padding: EdgeInsets.symmetric(
              vertical: 4, horizontal: 10), // Add some padding around the text
          decoration: BoxDecoration(
            color: right
                ? Colors.deepPurpleAccent
                : Colors.blueAccent, // Set the background color
            borderRadius: BorderRadius.circular(12.0), // Set border radius
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white, // Set text color for contrast
              fontSize: 17,
            ),
            textAlign: TextAlign.left, // Center the text
          ),
        ),
      ),
    );
  }
}

/// Displays detailed information about a SampleItem.
class SampleItemDetailsView extends StatelessWidget {
  const SampleItemDetailsView({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    List<List<dynamic>> messages = [
      ["Hallo", true],
      ["Wie geht's?", false],
      ["Das ist ein Test.", true],
      ["Flutter ist großartig!", false],
      ["Ich liebe Programmieren.", true],
      ["Das Wetter ist schön.", false],
      ["Hast du Pläne für heute?", true],
      ["Ich mag Pizza.", false],
      ["Lass uns einen Film schauen.", false],
      ["Das ist interessant.", false],
      ["Ich bin müde.", true],
      ["Was machst du gerade?", true],
      ["Ich habe ein neues Hobby.", true],
      ["Das ist eine lange Nachricht.", false],
      ["Ich freue mich auf das Wochenende.", true],
      ["Das ist eine zufällige Nachricht.", false],
      ["Ich lerne Dart.", true],
      ["Wie war dein Tag?", true],
      ["Ich genieße die Natur.", true],
      ["Das ist ein schöner Ort.", false],
      ["Meine letzte Nachricht.", false],
    ];
    messages = messages.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Chat with $userId'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length, // Number of items in the list
              reverse: true,
              itemBuilder: (context, i) {
                return AlignedTextBox(
                    text: messages[i][0], right: messages[i][1]);
              },
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40, left: 10, right: 10),
            child: TextField(
              decoration: InputDecoration(
                // border: OutlineInputBorder(),
                labelText: 'Enter your message',
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    // Handle send action
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
