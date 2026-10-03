import 'package:flutter/material.dart';
import '../widgets/exercise_set_widget.dart';
import 'package:careo_new/data/exercises_sets.dart';
import '../model/exercise_set.dart';

class FitnessScreen extends StatelessWidget {
  const FitnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Fitness',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          bottom: TabBar(
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Easy'),
              Tab(text: 'Medium'),
              Tab(text: 'Hard'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildExerciseList(context, ExerciseType.low),
            _buildExerciseList(context, ExerciseType.mid),
            _buildExerciseList(context, ExerciseType.hard),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList(
    BuildContext context,
    ExerciseType type,
  ) {
    final exercises =
        exerciseSets.where((e) => e.exerciseType == type).toList();

    if (exercises.isEmpty) {
      return Center(
        child: Text(
          'No exercises available',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 18,
              ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ExerciseSetWidget(
            exerciseSet: exercises[index],
          ),
        );
      },
    );
  }
}