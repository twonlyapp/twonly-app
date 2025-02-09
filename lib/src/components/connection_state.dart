import 'package:flutter/material.dart';

class ConnectionInfo extends StatefulWidget {
  const ConnectionInfo({super.key});

  @override
  State<ConnectionInfo> createState() => _ConnectionInfoWidgetState();
}

class _ConnectionInfoWidgetState extends State<ConnectionInfo> {
  int redColorOpacity = 100; // Initial opacity value
  bool redColorGoUp = true; // Direction of the opacity change
  double screenWidth = 0; // To hold the screen width

  @override
  void initState() {
    super.initState();
    _startColorAnimation();
  }

  void _startColorAnimation() {
    // Change the color every 200 milliseconds
    Future.delayed(Duration(milliseconds: 200), () {
      setState(() {
        if (redColorOpacity <= 100) {
          redColorGoUp = true;
        }
        if (redColorOpacity >= 150) {
          redColorGoUp = false;
        }
        if (redColorGoUp) {
          redColorOpacity += 10;
        } else {
          redColorOpacity -= 10;
        }
      });
      _startColorAnimation(); // Repeat the animation
    });
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width; // Get the screen width

    return Stack(
      children: [
        Positioned(
          top: 3, // Position it at the top
          left: (screenWidth * 0.5) / 2, // Center it horizontally
          child: AnimatedContainer(
            duration: Duration(milliseconds: 100),
            width: screenWidth * 0.5, // 50% of the screen width
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red[600]!
                    .withAlpha(redColorOpacity), // Use the animated opacity
                width: 2.0, // Red border width
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(10.0),
              ), // Rounded corners
            ),
          ),
        ),
      ],
    );
  }
}
