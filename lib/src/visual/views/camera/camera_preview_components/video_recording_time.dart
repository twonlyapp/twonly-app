import 'package:flutter/material.dart';

class VideoRecordingTimer extends StatelessWidget {
  const VideoRecordingTimer({
    required this.videoRecordingStarted,
    required this.currentTime,
    required this.maxRecordingTime,
    super.key,
  });
  final DateTime? videoRecordingStarted;

  /// Read once per tick by the camera view, so the ring and the stop that ends
  /// the recording agree on how far along it is.
  final DateTime currentTime;
  final Duration maxRecordingTime;

  @override
  Widget build(BuildContext context) {
    if (videoRecordingStarted == null) {
      return const SizedBox.shrink();
    }
    final elapsed = currentTime.difference(videoRecordingStarted!);
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            children: [
              Center(
                child: CircularProgressIndicator(
                  value: maxRecordingTime.inMilliseconds == 0
                      ? 0
                      : (elapsed.inMilliseconds /
                                maxRecordingTime.inMilliseconds)
                            .clamp(0.0, 1.0),
                  strokeWidth: 4,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                  backgroundColor: Colors.grey[300],
                ),
              ),
              Center(
                child: Text(
                  elapsed.inSeconds.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    shadows: [
                      Shadow(
                        color: Color.fromARGB(122, 0, 0, 0),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
