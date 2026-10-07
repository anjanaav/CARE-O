import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';

class GuardianDashboardScreen extends StatelessWidget {
  const GuardianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Welcome',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Stay connected with the people you care about.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            AppCard(
              onTap: () => context.push('/guardian/seniors'),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      Icons.people_outline,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Seniors',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View and manage the seniors connected to you.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            AppCard(
              onTap: () => context.push('/guardian/alerts'),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.errorContainer,
                    child: Icon(
                      Icons.notifications_none,
                      color: colors.onErrorContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alerts',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Check important alerts and notifications.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            AppCard(
              onTap: () => context.push('/guardian/calls'),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.secondaryContainer,
                    child: Icon(
                      Icons.video_call_outlined,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calls',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start or manage calls with connected seniors.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            AppCard(
              onTap: () => context.push('/guardian/profile'),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.tertiaryContainer,
                    child: Icon(
                      Icons.person_outline,
                      color: colors.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your guardian profile and settings.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}