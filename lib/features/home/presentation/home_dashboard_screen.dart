import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/presentation/providers/auth_providers.dart';

/// Home dashboard: greeting, upcoming medication reminders and quick actions.
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authRepositoryProvider).currentUser;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final firstName = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!.split(' ').first
        : '';

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final remindersRef = uid == null
        ? null
        : FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('medication_reminders')
            .orderBy('reminderTime')
            .limit(3);

    return Scaffold(
      appBar: AppBar(title: const Text('CARE-O'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            firstName.isNotEmpty ? '$greeting, $firstName' : greeting,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('How are you feeling today?', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),

          Text("Today's medication", style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          StreamBuilder<QuerySnapshot>(
            stream: remindersRef?.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const AppCard(
                  child: Text(
                    "We couldn't load your reminders. Please check your "
                    'connection and try again later.',
                  ),
                );
              }
              if (!snapshot.hasData) {
                return SizedBox(
                  height: 60,
                  child: Center(
                    child: Semantics(
                      label: 'Loading reminders',
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return AppCard(
                  onTap: () => context.push('/wellness/medication-reminders'),
                  child: const Text('No medication reminders yet — tap to add one.'),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final time = (data['reminderTime'] as Timestamp?)?.toDate();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      onTap: () => context.push('/wellness/medication-reminders'),
                      child: Row(
                        children: [
                          Icon(Icons.medication_outlined, color: theme.colorScheme.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(data['medicationName'] ?? '')),
                          if (time != null) Text(DateFormat.jm().format(time)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),
          Text('Quick actions', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.3,
            children: [
              FeatureCard(
                title: 'Breathing',
                icon: Icons.air,
                onTap: () => context.push('/wellness/breathing'),
              ),
              FeatureCard(
                title: 'Fitness',
                icon: Icons.fitness_center,
                onTap: () => context.push('/wellness/fitness'),
              ),
              FeatureCard(
                title: 'Meditation',
                icon: Icons.self_improvement,
                onTap: () => context.push('/wellness/meditation'),
              ),
              FeatureCard(
                title: 'Guardian',
                icon: Icons.shield_outlined,
                onTap: () => context.push('/connect/guardian'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
