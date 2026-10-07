import 'package:flutter/material.dart';

class GuardianAlertsScreen extends StatefulWidget {
  const GuardianAlertsScreen({super.key});

  @override
  State<GuardianAlertsScreen> createState() =>
      _GuardianAlertsScreenState();
}

class _GuardianAlertsScreenState
    extends State<GuardianAlertsScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = const [
    'All',
    'Unread',
    'Important',
  ];

  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _AlertsHeader(
                onMarkAllRead: _showNotAvailableMessage,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final selected = filter == _selectedFilter;

                    return FilterChip(
                      selected: selected,
                      label: Text(filter),
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                title: _selectedFilter == 'All'
                    ? 'All Alerts'
                    : '$_selectedFilter Alerts',
                count: 0,
              ),
              const SizedBox(height: 12),
              _EmptyAlertsState(
                onRefresh: _refresh,
              ),
              const SizedBox(height: 24),
              const _AlertInfoCard(
                icon: Icons.notifications_active_outlined,
                title: 'How Guardian Alerts work',
                message:
                    'Alerts from connected Seniors will appear here when '
                    'CARE-O detects an event that needs your attention.',
              ),
              const SizedBox(height: 12),
              const _AlertInfoCard(
                icon: Icons.security_outlined,
                title: 'Your connection is separate',
                message:
                    'Connecting or disconnecting a Senior is managed from '
                    'My Seniors. Alerts are only for attention and notification '
                    'events.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 350),
    );

    if (!mounted) return;

    setState(() {});
  }

  void _showNotAvailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'There are no alerts to mark as read.',
        ),
      ),
    );
  }
}

class _AlertsHeader extends StatelessWidget {
  final VoidCallback onMarkAllRead;

  const _AlertsHeader({
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                color: colors.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay informed',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Important events from your connected Seniors '
                    'will be shown here.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: onMarkAllRead,
                    icon: const Icon(
                      Icons.done_all_outlined,
                      size: 18,
                    ),
                    label: const Text('Mark all as read'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyAlertsState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyAlertsState({
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 36,
        ),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_outlined,
                size: 40,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No alerts right now',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You are all caught up. New attention-worthy events '
              'will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _AlertInfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: colors.primary,
              size: 25,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}