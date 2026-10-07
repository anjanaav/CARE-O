import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/guardian_connection_repository.dart';

class GuardianDashboardScreen extends StatefulWidget {
  const GuardianDashboardScreen({super.key});

  @override
  State<GuardianDashboardScreen> createState() =>
      _GuardianDashboardScreenState();
}

class _GuardianDashboardScreenState extends State<GuardianDashboardScreen> {
  final GuardianConnectionRepository _connectionRepository =
      GuardianConnectionRepository();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final horizontalPadding = screenWidth >= 1000
        ? 32.0
        : screenWidth >= 600
            ? 24.0
            : 16.0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _connectionRepository.watchConnectedSeniors(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _DashboardLoading(
                  horizontalPadding: horizontalPadding,
                );
              }

              if (snapshot.hasError) {
                return _DashboardError(
                  horizontalPadding: horizontalPadding,
                  onRetry: _refreshDashboard,
                );
              }

              final seniors = snapshot.data ?? <Map<String, dynamic>>[];

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  20,
                  horizontalPadding,
                  32,
                ),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildOverviewCard(
                    context,
                    seniorCount: seniors.length,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    title: 'Quick Actions',
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 28),
                  _buildSectionHeader(
                    context,
                    title: 'My Seniors',
                    actionLabel:
                        seniors.isEmpty ? null : 'See All',
                    onAction: seniors.isEmpty
                        ? null
                        : () {
                            context.go('/guardian/seniors');
                          },
                  ),
                  const SizedBox(height: 12),
                  if (seniors.isEmpty)
                    _buildEmptySeniors(context)
                  else
                    _buildSeniorList(
                      context,
                      seniors,
                      screenWidth,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    if (!mounted) {
      return;
    }

    setState(() {});

    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guardian Dashboard',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Stay connected with the people who matter most.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: 'Open profile',
          child: IconButton(
            tooltip: 'Profile',
            onPressed: () {
              context.go('/guardian/profile');
            },
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(
              Icons.person_outline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    BuildContext context, {
    required int seniorCount,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 420;

            final iconContainer = Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.people_alt_outlined,
                color: colorScheme.onPrimaryContainer,
                size: 30,
              ),
            );

            final description = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected Seniors',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  seniorCount == 0
                      ? 'No Seniors connected yet'
                      : seniorCount == 1
                          ? '1 Senior connected to your account'
                          : '$seniorCount Seniors connected to your account',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );

            final count = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(
                  '$seniorCount',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  seniorCount == 1 ? 'Senior' : 'Seniors',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      iconContainer,
                      const SizedBox(width: 16),
                      Expanded(
                        child: description,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  count,
                ],
              );
            }

            return Row(
              children: [
                iconContainer,
                const SizedBox(width: 16),
                Expanded(
                  child: description,
                ),
                const SizedBox(width: 16),
                count,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final actions = [
      _QuickActionData(
        title: 'My Seniors',
        subtitle: 'Manage connections',
        icon: Icons.people_outline,
        onTap: () {
          context.go('/guardian/seniors');
        },
      ),
      _QuickActionData(
        title: 'Alerts',
        subtitle: 'View notifications',
        icon: Icons.notifications_none_outlined,
        onTap: () {
          context.go('/guardian/alerts');
        },
      ),
      _QuickActionData(
        title: 'Calls',
        subtitle: 'Stay connected',
        icon: Icons.video_call_outlined,
        onTap: () {
          context.go('/guardian/calls');
        },
      ),
    ];

    if (screenWidth < 600) {
      return Column(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            _buildQuickActionCard(
              context,
              actions[i],
            ),
            if (i != actions.length - 1)
              const SizedBox(height: 12),
          ],
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenWidth >= 900 ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: screenWidth >= 900 ? 1.55 : 1.45,
      ),
      itemBuilder: (context, index) {
        return _buildQuickActionCard(
          context,
          actions[index],
        );
      },
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    _QuickActionData action,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  action.icon,
                  color: colorScheme.onSecondaryContainer,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeniorList(
    BuildContext context,
    List<Map<String, dynamic>> seniors,
    double screenWidth,
  ) {
    if (screenWidth < 900) {
      return Column(
        children: [
          for (var i = 0; i < seniors.length; i++) ...[
            _buildSeniorCard(
              context,
              seniors[i],
            ),
            if (i != seniors.length - 1)
              const SizedBox(height: 12),
          ],
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: seniors.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, index) {
        return _buildSeniorCard(
          context,
          seniors[index],
        );
      },
    );
  }

  Widget _buildSeniorCard(
    BuildContext context,
    Map<String, dynamic> senior,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = _displayName(senior);
    final email = _stringValue(senior['email']);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          context.go('/guardian/seniors');
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    colorScheme.primaryContainer,
                foregroundColor:
                    colorScheme.onPrimaryContainer,
                child: Text(
                  _initials(name),
                  style:
                      theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color:
                        colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            theme.textTheme.bodySmall?.copyWith(
                          color:
                              colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Connected',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Open $name',
                child: IconButton(
                  tooltip: 'Open Senior',
                  onPressed: () {
                    context.go('/guardian/seniors');
                  },
                  icon: const Icon(
                    Icons.chevron_right,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySeniors(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          24,
          32,
          24,
          30,
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_alt_1_outlined,
                size: 34,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Seniors connected yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with a Senior using their CARE-O connection code to start supporting them.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                context.go('/guardian/seniors');
              },
              icon: const Icon(
                Icons.person_add_alt_1,
              ),
              label: const Text(
                'Connect a Senior',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _displayName(
    Map<String, dynamic> senior,
  ) {
    final name = _stringValue(senior['name']);

    if (name.isNotEmpty) {
      return name;
    }

    final fullName = _stringValue(
      senior['fullName'],
    );

    if (fullName.isNotEmpty) {
      return fullName;
    }

    final email = _stringValue(
      senior['email'],
    );

    if (email.isNotEmpty) {
      return email;
    }

    return 'Senior';
  }

  String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  String _initials(String name) {
    final cleaned = name.trim();

    if (cleaned.isEmpty) {
      return 'S';
    }

    final parts = cleaned
        .split(RegExp(r'\s+'))
        .where(
          (part) => part.isNotEmpty,
        )
        .toList();

    if (parts.length == 1) {
      final value = parts.first;

      if (value.length >= 2) {
        return value
            .substring(0, 2)
            .toUpperCase();
      }

      return value.toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }
}

class _QuickActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _DashboardLoading extends StatelessWidget {
  final double horizontalPadding;

  const _DashboardLoading({
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        24,
        horizontalPadding,
        32,
      ),
      children: [
        const SizedBox(height: 8),
        const _LoadingBar(
          widthFactor: 0.58,
          height: 30,
        ),
        const SizedBox(height: 10),
        const _LoadingBar(
          widthFactor: 0.82,
          height: 18,
        ),
        const SizedBox(height: 28),
        _LoadingCard(
          color: colorScheme.surfaceContainerHighest,
          height: 120,
        ),
        const SizedBox(height: 24),
        const _LoadingBar(
          widthFactor: 0.35,
          height: 24,
        ),
        const SizedBox(height: 14),
        _LoadingCard(
          color: colorScheme.surfaceContainerHighest,
          height: 86,
        ),
        const SizedBox(height: 12),
        _LoadingCard(
          color: colorScheme.surfaceContainerHighest,
          height: 86,
        ),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  final double horizontalPadding;
  final Future<void> Function() onRetry;

  const _DashboardError({
    required this.horizontalPadding,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        80,
        horizontalPadding,
        32,
      ),
      children: [
        Icon(
          Icons.cloud_off_outlined,
          size: 64,
          color: colorScheme.error,
        ),
        const SizedBox(height: 18),
        Text(
          'Couldn’t load your dashboard',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please check your connection and try again.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Try Again',
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingBar extends StatelessWidget {
  final double widthFactor;
  final double height;

  const _LoadingBar({
    required this.widthFactor,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final Color color;
  final double height;

  const _LoadingCard({
    required this.color,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}