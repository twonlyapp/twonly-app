import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// animations from: https://googlefonts.github.io/noto-emoji-animation/

class EmojiAnimation extends StatelessWidget {
  final String emoji;
  static final Map<String, String> animatedIcons = {
    "❤": "red_heart.json",
    "💪": "💪.json",
    "🔥": "🔥.json",
    "😂": "😂.json",
    "😭": "😭.json",
    "🤯": "🤯.json",
    "🥰": "🥰.json",
    "🤠": "🤠.json",
    "❤️‍🔥": "red_heart_fire.json"
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
      return Lottie.asset("assets/animated_icons/${animatedIcons[emoji]}");
    } else {
      return Text(
        emoji,
        style: TextStyle(fontSize: 15), // Adjust the size as needed
      );
    }
  }
}

class EmojiAnimationFlying extends StatelessWidget {
  final String emoji;
  final Duration duration;
  final double startPosition;
  final int size;

  const EmojiAnimationFlying({
    super.key,
    required this.emoji,
    required this.duration,
    required this.startPosition,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
          begin: startPosition, end: 1), // Adjust end value as needed
      duration: duration,
      curve: Curves.linearToEaseOut,
      builder: (context, value, child) {
        return Padding(
          padding: EdgeInsets.only(bottom: 20 * value),
          child: Container(
            // opacity: 1 - value,
            child: SizedBox(
              width: size + 30 * value,
              child: EmojiAnimation(emoji: emoji),
            ),
          ),
        );
      },
    );
  }
}
