import 'package:flutter/material.dart';

class VideoRecordingTimer extends StatelessWidget {
  const VideoRecordingTimer({
    required this.videoRecordingStarted,
    required this.maxVideoRecordingTime,
    super.key,
  });
  final DateTime? videoRecordingStarted;
  final int maxVideoRecordingTime;

  @override
  Widget build(BuildContext context) {
    if (videoRecordingStarted != null) {
      final currentTime = DateTime.now();
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
                    value: currentTime
                            .difference(videoRecordingStarted!)
                            .inMilliseconds /
                        (maxVideoRecordingTime * 1000),
                    strokeWidth: 4,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    backgroundColor: Colors.grey[300],
                  ),
                ),
                Center(
                  child: Text(
                    currentTime
                        .difference(videoRecordingStarted!)
                        .inSeconds
                        .toString(),
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
    } else {
      return const SizedBox.shrink();
    }
  }
}
