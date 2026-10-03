import 'package:flutter/material.dart';
import '../widgets/exercise_set_widget.dart';
import 'package:careo_new/data/exercises_sets.dart'; // Ensure this contains correct data
import '../model/exercise_set.dart'; // Import this if ExerciseType is missing

class FitnessScreen extends StatelessWidget {
  const FitnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Fitness',
            style: TextStyle(color: const Color.fromARGB(255, 240, 237, 237), fontSize: 28), // Increased font size
          ),
          bottom: TabBar(
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.black,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Readable font size for elders
            tabs: [
              Tab(text: 'Easy'),
              Tab(text: 'Medium'),
              Tab(text: 'Hard'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildExerciseList(ExerciseType.low),
            _buildExerciseList(ExerciseType.mid),
            _buildExerciseList(ExerciseType.hard),
          ],
        ),
      ),
    );
  }

  // Helper method to create a tab view with exercises
  Widget _buildExerciseList(ExerciseType type) {
    final exercises = exerciseSets.where((e) => e.exerciseType == type).toList();

    if (exercises.isEmpty) {
      return Center(child: Text('No exercises available', style: TextStyle(fontSize: 18)));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0), // Increased spacing between widgets
          child: ExerciseSetWidget(exerciseSet: exercises[index]),
        );
      },
    );
  }
}
