import 'package:flutter/material.dart';
import 'breathing_exercise_screen.dart';
import 'meditation_video_screen.dart';
import 'yoga_screen.dart';

class MeditationScreen extends StatelessWidget {
  const MeditationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Meditation',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: colorScheme.primary,
            indicatorWeight: 3,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(
                icon: Icon(Icons.play_circle_fill),
                text: 'Videos',
              ),
              Tab(
                icon: Icon(Icons.air),
                text: 'Breathing',
              ),
              Tab(
                icon: Icon(Icons.sports_gymnastics),
                text: 'Yoga',
              ),
            ],
          ),
          elevation: 4,
        ),
        body: TabBarView(
          children: [
            MeditationVideoScreen(),
            BreathingExerciseScreen(),
            YogaScreen(),
          ],
        ),
      ),
    );
  }
}