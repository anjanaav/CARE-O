//import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';

class Exercise {
  final String name;
  final Duration duration;
  final int noOfReps;
  final String videoUrl;
  late VideoPlayerController controller; // ✅ Use `late` to initialize later

  Exercise({
    required this.name,
    required this.duration,
    required this.noOfReps,
    required this.videoUrl,
  }) {
    controller = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        controller.setLooping(true); // ✅ Ensures smooth playback
      });
  }

  void dispose() {
    controller.dispose(); // ✅ Properly dispose of the controller
  }
}
