import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../guardian/data/guardian_connection_repository.dart';

class ConnectTabScreen extends StatefulWidget {
  const ConnectTabScreen({super.key});

  @override
  State<ConnectTabScreen> createState() => _ConnectTabScreenState();
}

class _ConnectTabScreenState extends State<ConnectTabScreen> {
  final GuardianConnectionRepository _connectionRepository =
      GuardianConnectionRepository();

  bool _generatingCode = false;
  String? _generatedCode;

  Future<void> _generateGuardianCode() async {
    if (_generatingCode) return;

    setState(() {
      _generatingCode = true;
    });

    // Capture the messenger before the async gap.
    final messenger = ScaffoldMessenger.of(context);

    try {
      final code = await _connectionRepository.createGuardianCode();

      if (!mounted) return;

      setState(() {
        _generatedCode = code;
      });

      await _showCodeDialog(code);
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not create connection code: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _generatingCode = false;
        });
      }
    }
  }

  Future<void> _showCodeDialog(String code) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colors = theme.colorScheme;

        return AlertDialog(
          title: const Text('Guardian Connection Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Give this code to your Guardian. '
                'It will expire in 30 minutes.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SelectableText(
                  code,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your Guardian should enter this code '
                'from their CARE-O Guardian account.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: code),
                );

                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Code copied to clipboard'),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _disconnectGuardian(
    String guardianUid,
    String guardianName,
  ) async {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Disconnect Guardian?'),
          content: Text(
            'This will remove $guardianName from your connected '
            'Guardian list.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Disconnect'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDisconnect != true) return;

    // Capture messenger before the async repository call.
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _connectionRepository.disconnectGuardian(guardianUid);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Guardian disconnected'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not disconnect Guardian: $e',
          ),
        ),
      );
    }
  }

  Widget _buildConnectedGuardians(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _connectionRepository.watchConnectedGuardians(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppCard(
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: colors.error,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Unable to load connected Guardians.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final guardians = snapshot.data ?? [];

        if (guardians.isEmpty) {
          return AppCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.surfaceContainerHighest,
                  child: Icon(
                    Icons.person_add_alt_1_outlined,
                    size: 28,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No Guardian connected yet',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Generate a CARE-O connection code above '
                  'and give it to your Guardian.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: guardians.map((guardian) {
            final guardianUid =
                guardian['uid'] as String? ?? '';

            final guardianName =
                guardian['guardianName'] as String? ?? 'Guardian';

            final guardianEmail =
                guardian['guardianEmail'] as String? ?? '';

            return Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.md,
              ),
              child: AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              colors.primaryContainer,
                          child: Icon(
                            Icons.shield_outlined,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                guardianName,
                                style:
                                    theme.textTheme.titleMedium,
                              ),
                              if (guardianEmail.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  guardianEmail,
                                  style: theme
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color:
                                        colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Connected',
                                    style: theme
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                      color: colors.primary,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Disconnect Guardian',
                          onPressed: guardianUid.isEmpty
                              ? null
                              : () => _disconnectGuardian(
                                    guardianUid,
                                    guardianName,
                                  ),
                          icon: const Icon(
                            Icons.link_off_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGeneratedCodeCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final code = _generatedCode;

    if (code == null) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.vpn_key_outlined,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Your active connection code',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SelectableText(
              code,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Expires in 30 minutes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  // Capture the messenger before the async gap.
                  final messenger =
                      ScaffoldMessenger.of(context);

                  await Clipboard.setData(
                    ClipboardData(text: code),
                  );

                  if (!mounted) return;

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Code copied'),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.copy,
                  size: 18,
                ),
                label: const Text('Copy'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Stay connected',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Connect your CARE-O account with your family '
              'or Guardian.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              onTap: _generatingCode
                  ? null
                  : _generateGuardianCode,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      Icons.shield_outlined,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connect a Guardian',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Generate a secure code and give it '
                          'to your Guardian.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_generatingCode)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildGeneratedCodeCard(context),
            if (_generatedCode != null)
              const SizedBox(height: AppSpacing.lg),
            Text(
              'Connected Guardians',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildConnectedGuardians(context),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/connect/guardian',
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        colors.secondaryContainer,
                    child: Icon(
                      Icons.people_outline,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Family & Care Circle',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage trusted contacts, caregivers '
                          'and emergency contacts.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(
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
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}