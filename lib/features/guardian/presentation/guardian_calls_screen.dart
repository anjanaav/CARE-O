import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/guardian_connection_repository.dart';

class GuardianCallsScreen extends StatefulWidget {
  const GuardianCallsScreen({super.key});

  @override
  State<GuardianCallsScreen> createState() => _GuardianCallsScreenState();
}

class _GuardianCallsScreenState extends State<GuardianCallsScreen> {
  final GuardianConnectionRepository _repository =
      GuardianConnectionRepository();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
        centerTitle: false,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _repository.watchConnectedSeniors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Unable to load your connected Seniors.',
              onRetry: () => setState(() {}),
            );
          }

          final seniors = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                32,
              ),
              children: [
                _CallsHeader(
                  connectedCount: seniors.length,
                ),

                const SizedBox(height: 24),

                Text(
                  'Start a Call',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                if (seniors.isEmpty)
                  _NoSeniorsState(
                    onConnect: () {
                      context.go('/guardian/seniors');
                    },
                  )
                else
                  ...seniors.map(
                    (senior) {
                      final uid =
                          senior['uid'] as String? ?? '';

                      final name =
                          senior['seniorName'] as String? ??
                              'Senior';

                      final email =
                          senior['seniorEmail'] as String? ??
                              '';

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: _SeniorCallCard(
                          name: name,
                          email: email,
                          onVideoCall: uid.isEmpty
                              ? null
                              : () => _startVideoCall(
                                    uid,
                                    name,
                                  ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 16),

                _CallsInfoCard(
                  icon: Icons.video_call_outlined,
                  title: 'Video calls',
                  message:
                      'Start a secure video call with any connected '
                      'Senior from this screen.',
                ),

                const SizedBox(height: 12),

                _CallsInfoCard(
                  icon: Icons.people_outline,
                  title: 'Manage connections',
                  message:
                      'Adding or disconnecting Seniors is handled '
                      'from My Seniors so communication and connection '
                      'management stay separate.',
                  actionLabel: 'Open My Seniors',
                  onAction: () {
                    context.go('/guardian/seniors');
                  },
                ),
              ],
            ),
          );
        },
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

  void _startVideoCall(
    String seniorUid,
    String seniorName,
  ) {
    final channelName = _buildChannelName(seniorUid);

    context.push(
      '/connect/video-call/${Uri.encodeComponent(channelName)}',
    );
  }

  String _buildChannelName(String seniorUid) {
    final cleanedUid = seniorUid.trim();

    if (cleanedUid.isEmpty) {
      return 'careo-call';
    }

    return 'careo-$cleanedUid';
  }
}

class _CallsHeader extends StatelessWidget {
  final int connectedCount;

  const _CallsHeader({
    required this.connectedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final seniorLabel =
        connectedCount == 1 ? 'Senior' : 'Seniors';

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.video_call_outlined,
                size: 30,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay connected',
                    style:
                        theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$connectedCount connected $seniorLabel',
                    style:
                        theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
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

class _SeniorCallCard extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback? onVideoCall;

  const _SeniorCallCard({
    required this.name,
    required this.email,
    required this.onVideoCall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final displayName =
        name.trim().isEmpty ? 'Senior' : name.trim();

    final initial =
        displayName.substring(0, 1).toUpperCase();

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    initial,
                    style:
                        theme.textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style:
                            theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (email.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Connected',
                            style:
                                theme.textTheme.bodySmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onVideoCall,
                icon: const Icon(
                  Icons.video_call_outlined,
                ),
                label: const Text('Start Video Call'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSeniorsState extends StatelessWidget {
  final VoidCallback onConnect;

  const _NoSeniorsState({
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 58,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Seniors connected',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with a Senior before starting a call.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.link),
              label: const Text('Go to My Seniors'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallsInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CallsInfoCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
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
              size: 25,
              color: colors.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  if (actionLabel != null &&
                      onAction != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
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
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}