import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';

class ActivitiesTabScreen extends StatelessWidget {
  const ActivitiesTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activities'), automaticallyImplyLeading: false),
      body: GridView.count(
        padding: const EdgeInsets.all(AppSpacing.md),
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.2,
        children: [
          FeatureCard(
            title: 'Games',
            subtitle: 'Tic-Tac-Toe & more',
            icon: Icons.sports_esports_outlined,
            onTap: () => context.push('/activities/games'),
          ),
          FeatureCard(
            title: 'Memory',
            subtitle: 'Brain training',
            icon: Icons.psychology_outlined,
            onTap: () => context.push('/activities/memory'),
          ),
          FeatureCard(
            title: 'Music',
            subtitle: 'Relax and unwind',
            icon: Icons.music_note_outlined,
            onTap: () => context.push('/activities/music'),
          ),
          FeatureCard(
            title: 'Devotional',
            subtitle: 'Prayers, songs & quotes',
            icon: Icons.book_outlined,
            onTap: () => context.push('/activities/devotional'),
          ),
          FeatureCard(
            title: 'Quotes',
            subtitle: 'Daily inspiration',
            icon: Icons.format_quote_outlined,
            onTap: () => context.push('/activities/quotes'),
          ),
          FeatureCard(
            title: 'Entertainment',
            subtitle: 'Videos & more',
            icon: Icons.movie_outlined,
            onTap: () => context.push('/activities/entertainment'),
          ),
        ],
      ),
    );
  }
}
