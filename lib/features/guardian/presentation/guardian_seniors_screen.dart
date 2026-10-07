import 'package:flutter/material.dart';

import '../data/guardian_repository.dart';

class GuardianSeniorsScreen extends StatefulWidget {
  const GuardianSeniorsScreen({super.key});

  @override
  State<GuardianSeniorsScreen> createState() =>
      _GuardianSeniorsScreenState();
}

class _GuardianSeniorsScreenState extends State<GuardianSeniorsScreen> {
  final GuardianRepository _repository = GuardianRepository();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family & Care Circle'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Guardian>>(
          stream: _repository.watchGuardians(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorState(
                message: 'Unable to load your care circle.',
                onRetry: () {
                  setState(() {});
                },
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final guardians = snapshot.data ?? [];

            if (guardians.isEmpty) {
              return const _EmptyState();
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                32,
              ),
              children: [
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.family_restroom,
                            size: 30,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connected Seniors',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                guardians.length == 1
                                    ? '1 senior is connected.'
                                    : '${guardians.length} seniors are connected.',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your Care Circle',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...guardians.map(
                  (guardian) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GuardianCard(
                      guardian: guardian,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GuardianCard extends StatelessWidget {
  final Guardian guardian;

  const _GuardianCard({
    required this.guardian,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                guardian.name.isNotEmpty
                    ? guardian.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guardian.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _roleLabel(guardian.role),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (guardian.relationship.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.people_outline,
                      text: guardian.relationship,
                    ),
                  ],
                  if (guardian.phone.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      text: guardian.phone,
                    ),
                  ],
                  if (guardian.email.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      text: guardian.email,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(GuardianRole role) {
    switch (role) {
      case GuardianRole.primaryGuardian:
        return 'Primary Guardian';
      case GuardianRole.guardian:
        return 'Guardian';
      case GuardianRole.familyMember:
        return 'Family Member';
      case GuardianRole.caregiver:
        return 'Caregiver';
      case GuardianRole.emergencyContact:
        return 'Emergency Contact';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 72,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'No connected seniors',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Connected seniors will appear here once they are linked to your account.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}