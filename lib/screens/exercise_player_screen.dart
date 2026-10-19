
import 'package:flutter/material.dart';

import '../model/exercise.dart';
import '../model/exercise_set.dart';
import '../widgets/video_controls_widget.dart';
import '../widgets/exercise_video_player.dart';

class ExercisePage extends StatefulWidget {
  final ExerciseSet exerciseSet;

  const ExercisePage({
    super.key,
    required this.exerciseSet,
  });

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  late final PageController controller;
  late Exercise currentExercise;

  @override
  void initState() {
    super.initState();

    controller = PageController();
    currentExercise = widget.exerciseSet.exercises.first;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _changeExercise(int index) {
    setState(() {
      currentExercise = widget.exerciseSet.exercises[index];
    });
  }

  Future<void> _goToNextVideo() async {
    if (!controller.hasClients) return;

    final currentPage = controller.page?.round() ?? 0;
    final lastPage = widget.exerciseSet.exercises.length - 1;

    if (currentPage >= lastPage) return;

    await controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _goToPreviousVideo() async {
    if (!controller.hasClients) return;

    final currentPage = controller.page?.round() ?? 0;

    if (currentPage <= 0) return;

    await controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          currentExercise.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: widget.exerciseSet.exercises.length,
                onPageChanged: _changeExercise,
                itemBuilder: (context, index) {
                  final exercise =
                      widget.exerciseSet.exercises[index];

                  return ExerciseVideoPlayer(
                    key: ValueKey(exercise.videoUrl),
                    exercise: exercise,
                    onInitialized: () {
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              color: colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: VideoControlsWidget(
                exercise: currentExercise,
                onTogglePlaying: (isPlaying) {
                  final videoController =
                      currentExercise.controller;

                  if (!videoController.value.isInitialized) {
                    return;
                  }

                  setState(() {
                    if (isPlaying) {
                      videoController.play();
                    } else {
                      videoController.pause();
                    }
                  });
                },
                onNextVideo: _goToNextVideo,
                onRewindVideo: _goToPreviousVideo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
