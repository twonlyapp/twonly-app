import 'package:flutter/material.dart';

/// Full-screen white overlay used as a "flash" when taking selfies
/// with the front camera and flash enabled.
class CameraSelfieFlash extends StatelessWidget {
  const CameraSelfieFlash({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          color: Colors.white,
        ),
      ),
    );
  }
}
