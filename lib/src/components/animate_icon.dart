import 'package:cv/cv.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// animations from: https://googlefonts.github.io/noto-emoji-animation/

class EmojiAnimation extends StatelessWidget {
  final String emoji;
  static final Map<String, String> animatedIcons = {
    "❤": "red_heart.json",
    "💪": "💪.json",
    "🔥": "🔥.json",
    "🤠": "🤠.json",
    "🤯": "🤯.json",
    "🥰": "🥰.json",
    "😂": "😂.json",
    "😭": "😭.json",
  };

  const EmojiAnimation({super.key, required this.emoji});

  static bool supported(String emoji) {
    return animatedIcons.containsKey(emoji);
  }

  @override
  Widget build(BuildContext context) {
    // List of emojis and their corresponding Lottie file names

    // Check if the emoji has a corresponding Lottie animation
    if (animatedIcons.containsKey(emoji)) {
      return Lottie.asset(
          "assets/animated_icons/${animatedIcons.getValue(emoji)}");
    } else {
      return Text(
        emoji,
        style: TextStyle(fontSize: 100), // Adjust the size as needed
      );
    }
  }
}
