import 'package:careo_new/model/exercise_set.dart';
import 'package:careo_new/screens/exercise_player_screen.dart';
import 'package:flutter/material.dart';

class ExerciseSetWidget extends StatelessWidget {
  final ExerciseSet exerciseSet;

  const ExerciseSetWidget({
    super.key,
    required this.exerciseSet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ExercisePage(
                exerciseSet: exerciseSet,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildText(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AspectRatio(
                  aspectRatio: 1.25,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      exerciseSet.imageUrl,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.fitness_center,
                            size: 36,
                            color: colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildText(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final exerciseCount = exerciseSet.exercises.length;
    final minutes = exerciseSet.totalDuration;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          exerciseSet.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$exerciseCount exercises • $minutes mins',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
