import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';

class WellnessTabScreen extends StatelessWidget {
  const WellnessTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wellness'), automaticallyImplyLeading: false),
      body: GridView.count(
        padding: const EdgeInsets.all(AppSpacing.md),
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.2,
        children: [
          FeatureCard(
            title: 'Fitness',
            subtitle: 'Guided exercise sets',
            icon: Icons.fitness_center,
            onTap: () => context.push('/wellness/fitness'),
          ),
          FeatureCard(
            title: 'Yoga',
            subtitle: 'Poses & routines',
            icon: Icons.self_improvement,
            onTap: () => context.push('/wellness/yoga'),
          ),
          FeatureCard(
            title: 'Breathing',
            subtitle: 'Calm, guided sessions',
            icon: Icons.air,
            onTap: () => context.push('/wellness/breathing'),
          ),
          FeatureCard(
            title: 'Meditation',
            subtitle: 'Relaxation sessions',
            icon: Icons.spa_outlined,
            onTap: () => context.push('/wellness/meditation'),
          ),
          FeatureCard(
            title: 'Medication',
            subtitle: 'Reminders & intake log',
            icon: Icons.medication_outlined,
            onTap: () => context.push('/wellness/medication-reminders'),
          ),
          FeatureCard(
            title: 'Helpline',
            subtitle: 'Get support',
            icon: Icons.support_agent,
            onTap: () => context.push('/wellness/helpline'),
          ),
        ],
      ),
    );
  }
}
