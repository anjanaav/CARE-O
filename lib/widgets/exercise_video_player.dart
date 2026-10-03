// ignore_for_file: library_private_types_in_public_api

import 'package:careo_new/model/exercise.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ExerciseVideoPlayer extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback onInitialized;

  // ignore: use_super_parameters
  const ExerciseVideoPlayer({
    required this.exercise,
    required this.onInitialized,
    Key? key,
  }) : super(key: key);

  @override
  _ExerciseVideoPlayerState createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    try {
      controller = VideoPlayerController.asset(widget.exercise.videoUrl)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            controller.setLooping(true);
            controller.play();
            widget.exercise.controller = controller;
            widget.onInitialized();
          }
        }).catchError((error) {
          debugPrint("Video initialization error: \$error");
        });
    } catch (e) {
      debugPrint("Error loading video: \$e");
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.expand(
        child: controller.value.isInitialized
            ? VideoPlayer(controller)
            : const Center(child: CircularProgressIndicator()),
      );
}
