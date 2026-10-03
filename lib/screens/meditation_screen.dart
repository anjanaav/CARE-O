import 'package:flutter/material.dart';
import 'breathing_exercise_screen.dart';
import 'meditation_video_screen.dart';
import 'yoga_screen.dart';

class MeditationScreen extends StatelessWidget {
  const MeditationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meditation'),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.orange,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.play_circle_fill), text: "Videos"),
              Tab(icon: Icon(Icons.air), text: "Breathing"),
              Tab(icon: Icon(Icons.sports_gymnastics), text: "Yoga"),
            ],
          ),
          elevation: 4,
        ),
        body: TabBarView(
          children: [
            const MeditationVideoScreen(), // Videos
            const BreathingExerciseScreen(), // Breathing
            YogaScreen(), // Yoga
          ],
        ),
      ),
    );
  }
}
