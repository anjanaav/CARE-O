import 'package:flutter/material.dart';

import '../data/guardian_connection_repository.dart';

class GuardianSeniorsScreen extends StatefulWidget {
  const GuardianSeniorsScreen({super.key});

  @override
  State<GuardianSeniorsScreen> createState() => _GuardianSeniorsScreenState();
}

class _GuardianSeniorsScreenState extends State<GuardianSeniorsScreen> {
  final GuardianConnectionRepository _connectionRepository =
      GuardianConnectionRepository();

  final TextEditingController _codeController = TextEditingController();

  bool _isConnecting = false;
  String? _connectionError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _connectToSenior() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _connectionError = 'Please enter a connection code.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });

    try {
      await _connectionRepository.connectUsingCode(code);

      if (!mounted) return;

      _codeController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senior connected successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _isConnecting = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isConnecting = false;
        _connectionError = _friendlyError(error);
      });
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('Invalid connection code')) {
      return 'Invalid connection code. Please check the code and try again.';
    }

    if (message.contains('already been used')) {
      return 'This connection code has already been used.';
    }

    if (message.contains('has expired')) {
      return 'This connection code has expired. Ask the Senior for a new code.';
    }

    if (message.contains('Only Guardian accounts')) {
      return 'Only Guardian accounts can connect to a Senior.';
    }

    if (message.contains('could not be found')) {
      return 'The Senior account could not be found.';
    }

    if (message.contains('not a Senior account')) {
      return 'The selected account is not a Senior account.';
    }

    if (message.contains('itself')) {
      return 'You cannot connect an account to itself.';
    }

    if (message.contains('permission-denied')) {
      return 'You do not have permission to create this connection.';
    }

    if (message.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }

    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Please enter a valid connection code.';
    }

    if (error is StateError) {
      return error.message;
    }

    return 'Unable to connect to the Senior. Please try again.';
  }

  Future<void> _disconnectSenior(Map<String, dynamic> senior) async {
    final seniorUid = senior['uid'] as String?;

    if (seniorUid == null || seniorUid.isEmpty) {
      return;
    }

    final seniorName =
        (senior['seniorName'] as String?)?.trim().isNotEmpty == true
            ? senior['seniorName'] as String
            : 'this Senior';

    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          title: const Text('Disconnect Senior?'),
          content: Text(
            'Are you sure you want to disconnect $seniorName from your Care Circle?',
            style: theme.textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Disconnect'),
            ),
          ],
        );
      },
    );

    if (shouldDisconnect != true || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _connectionRepository.disconnectSenior(seniorUid);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Senior disconnected.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(_friendlyError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildConnectionCard(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.person_add_alt_1_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect to a Senior',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter the CARE-O connection code provided by the Senior.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              enabled: !_isConnecting,
              onSubmitted: (_) => _connectToSenior(),
              decoration: InputDecoration(
                labelText: 'Connection code',
                hintText: 'CARE-XXXXXXXX',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                errorText: _connectionError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isConnecting ? null : _connectToSenior,
                icon: _isConnecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.link_rounded),
                label: Text(
                  _isConnecting ? 'Connecting...' : 'Connect to Senior',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connection codes are temporary and can only be used once.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeniorCard(
    BuildContext context,
    Map<String, dynamic> senior,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = (senior['seniorName'] as String?)?.trim();
    final email = (senior['seniorEmail'] as String?)?.trim();

    final displayName =
        name != null && name.isNotEmpty ? name : 'Senior';

    final displayEmail =
        email != null && email.isNotEmpty ? email : 'No email available';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(
                Icons.person_rounded,
                size: 30,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 17,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          displayEmail,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Connected',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Senior options',
              onSelected: (value) {
                if (value == 'disconnect') {
                  _disconnectSenior(senior);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'disconnect',
                  child: Text('Disconnect'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedSeniors(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _connectionRepository.watchConnectedSeniors(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 42,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load connected Seniors',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final seniors = snapshot.data ?? [];

        if (seniors.isEmpty) {
          return Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 52,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No connected Seniors yet',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask a Senior to generate a CARE-O connection code and enter it above.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            for (var index = 0; index < seniors.length; index++) ...[
              _buildSeniorCard(context, seniors[index]),
              if (index < seniors.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Seniors'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 700 ? 32.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 760,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Family & Care Circle',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage the Seniors connected to your Guardian account.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildConnectionCard(context),
                      const SizedBox(height: 28),
                      Text(
                        'Connected Seniors',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildConnectedSeniors(context),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

