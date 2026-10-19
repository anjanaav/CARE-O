
import 'package:careo_new/model/exercise.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ExerciseVideoPlayer extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback onInitialized;

  const ExerciseVideoPlayer({
    super.key,
    required this.exercise,
    required this.onInitialized,
  });

  @override
  State<ExerciseVideoPlayer> createState() =>
      _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer> {
  late final VideoPlayerController controller;

  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.asset(
      widget.exercise.videoUrl,
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await controller.initialize();

      if (!mounted) return;

      await controller.setLooping(true);

      // Keep the controller available to the existing exercise controls.
      widget.exercise.controller = controller;

      setState(() {
        _hasError = false;
      });

      widget.onInitialized();

      await controller.play();
    } catch (error, stackTrace) {
      debugPrint('Video initialization error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 56,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load this exercise video.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please check that the video asset exists.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!controller.value.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          }

          final videoSize = controller.value.size;

          if (videoSize.width <= 0 || videoSize.height <= 0) {
            return const Center(
              child: Text(
                'Invalid video dimensions.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final videoAspectRatio = controller.value.aspectRatio;

          final availableWidth = constraints.maxWidth;
          final availableHeight = constraints.maxHeight;

          // Fit the complete video inside the available space.
          // Never stretch the video to fill the entire screen.
          double displayWidth;
          double displayHeight;

          if (availableWidth / availableHeight >
              videoAspectRatio) {
            displayHeight = availableHeight;
            displayWidth = displayHeight * videoAspectRatio;
          } else {
            displayWidth = availableWidth;
            displayHeight = displayWidth / videoAspectRatio;
          }

          return Center(
            child: SizedBox(
              width: displayWidth,
              height: displayHeight,
              child: VideoPlayer(controller),
            ),
          );
        },
      ),
    );
  }
}
