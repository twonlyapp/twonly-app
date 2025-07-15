import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

class SendToWidget extends StatelessWidget {
  const SendToWidget({
    required this.sendTo,
    super.key,
  });
  final String sendTo;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 24,
      decoration: TextDecoration.none,
      shadows: [
        Shadow(
          color: Color.fromARGB(122, 0, 0, 0),
          blurRadius: 5,
        ),
      ],
    );

    final boldTextStyle = textStyle.copyWith(
      fontWeight: FontWeight.normal,
      fontSize: 28,
    );

    return Positioned(
      right: 0,
      left: 0,
      top: 50,
      child: Column(
        children: [
          Text(
            context.lang.cameraPreviewSendTo,
            textAlign: TextAlign.center,
            style: textStyle,
          ),
          Text(
            sendTo,
            textAlign: TextAlign.center,
            style: boldTextStyle, // Use the bold text style here
          ),
        ],
      ),
    );
  }

  String getContactDisplayName(String contact) {
    // Replace this with your actual logic to get the contact display name
    return contact; // Placeholder implementation
  }
}
