import 'package:flutter/material.dart';

import '../data/guardian_repository.dart';

class GuardianScreen extends StatefulWidget {
  const GuardianScreen({super.key});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  final GuardianRepository _repository = GuardianRepository();

  final GuardianRole _selectedRole = GuardianRole.guardian;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family & Care Circle'),
        centerTitle: false,
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

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: guardians.isEmpty
                  ? _EmptyState(
                      onAddGuardian: _showAddGuardianDialog,
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        100,
                      ),
                      children: [
                        _HeaderCard(
                          guardiansCount: guardians.length,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Your Care Circle',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...guardians.map(
                          (guardian) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _GuardianCard(
                              guardian: guardian,
                              onEdit: () =>
                                  _showEditGuardianDialog(guardian),
                              onDelete: () =>
                                  _confirmDeleteGuardian(guardian),
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGuardianDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Guardian'),
      ),
    );
  }

  Future<void> _showAddGuardianDialog() async {
    final result = await showDialog<_GuardianFormResult>(
      context: context,
      builder: (context) {
        return _GuardianFormDialog(
          title: 'Add Guardian',
          selectedRole: _selectedRole,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    // Capture the messenger before the repository async operation.
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _repository.addGuardian(
        name: result.name,
        phone: result.phone,
        email: result.email,
        relationship: result.relationship,
        role: result.role,
        notifyMissedMedication: result.notifyMissedMedication,
      );

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Guardian added successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not add guardian: ${_friendlyError(e)}',
          ),
        ),
      );
    }
  }

  Future<void> _showEditGuardianDialog(Guardian guardian) async {
    final result = await showDialog<_GuardianFormResult>(
      context: context,
      builder: (context) {
        return _GuardianFormDialog(
          title: 'Edit Guardian',
          guardian: guardian,
          selectedRole: guardian.role,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    // Capture the messenger before the repository async operation.
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _repository.updateGuardian(
        guardian.id,
        name: result.name,
        phone: result.phone,
        email: result.email,
        relationship: result.relationship,
        role: result.role,
        notifyMissedMedication: result.notifyMissedMedication,
      );

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Guardian updated successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not update guardian: ${_friendlyError(e)}',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteGuardian(Guardian guardian) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return AlertDialog(
          title: const Text('Remove Guardian?'),
          content: Text(
            'Remove ${guardian.name} from your Care Circle?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    // Capture the messenger before the repository async operation.
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _repository.deleteGuardian(guardian.id);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Guardian removed.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not remove guardian: ${_friendlyError(e)}',
          ),
        ),
      );
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('permission-denied')) {
      return 'You do not have permission to perform this action.';
    }

    if (message.contains('network')) {
      return 'Please check your internet connection.';
    }

    return message
        .replaceFirst('Exception: ', '')
        .replaceFirst('StateError: ', '');
  }
}

class _HeaderCard extends StatelessWidget {
  final int guardiansCount;

  const _HeaderCard({
    required this.guardiansCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your trusted people',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    guardiansCount == 1
                        ? '1 person is part of your Care Circle.'
                        : '$guardiansCount people are part of your Care Circle.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

class _GuardianCard extends StatelessWidget {
  final Guardian guardian;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GuardianCard({
    required this.guardian,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
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
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Guardian options',
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline),
                        title: Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (guardian.relationship.trim().isNotEmpty)
              _InfoRow(
                icon: Icons.people_outline,
                text: guardian.relationship,
              ),
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
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    guardian.notifyMissedMedication
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      guardian.notifyMissedMedication
                          ? 'Missed medication alerts enabled'
                          : 'Missed medication alerts disabled',
                      style: theme.textTheme.bodySmall,
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
  final VoidCallback onAddGuardian;

  const _EmptyState({
    required this.onAddGuardian,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 70),
        Icon(
          Icons.family_restroom_outlined,
          size: 82,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Your Care Circle is empty',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Add trusted family members, guardians, caregivers, '
          'or emergency contacts so they can support you when needed.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: onAddGuardian,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add Guardian'),
        ),
      ],
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

class _GuardianFormResult {
  final String name;
  final String phone;
  final String email;
  final String relationship;
  final GuardianRole role;
  final bool notifyMissedMedication;

  const _GuardianFormResult({
    required this.name,
    required this.phone,
    required this.email,
    required this.relationship,
    required this.role,
    required this.notifyMissedMedication,
  });
}

class _GuardianFormDialog extends StatefulWidget {
  final String title;
  final Guardian? guardian;
  final GuardianRole selectedRole;

  const _GuardianFormDialog({
    required this.title,
    required this.selectedRole,
    this.guardian,
  });

  @override
  State<_GuardianFormDialog> createState() =>
      _GuardianFormDialogState();
}

class _GuardianFormDialogState extends State<_GuardianFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _relationshipController;

  late GuardianRole _role;
  late bool _notifyMissedMedication;

  @override
  void initState() {
    super.initState();

    final guardian = widget.guardian;

    _nameController = TextEditingController(
      text: guardian?.name ?? '',
    );

    _phoneController = TextEditingController(
      text: guardian?.phone ?? '',
    );

    _emailController = TextEditingController(
      text: guardian?.email ?? '',
    );

    _relationshipController = TextEditingController(
      text: guardian?.relationship ?? '',
    );

    _role = guardian?.role ?? widget.selectedRole;

    _notifyMissedMedication =
        guardian?.notifyMissedMedication ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _relationshipController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (email.isEmpty) {
                      return null;
                    }

                    final validEmail = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email);

                    if (!validEmail) {
                      return 'Enter a valid email address.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _relationshipController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    prefixIcon: Icon(Icons.people_outline),
                    hintText: 'e.g. Daughter, Son, Caregiver',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GuardianRole>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: GuardianRole.values.map(
                    (role) {
                      return DropdownMenuItem<GuardianRole>(
                        value: role,
                        child: Text(_roleLabel(role)),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _role = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Missed medication alerts',
                  ),
                  subtitle: const Text(
                    'Notify this person when medication is missed.',
                  ),
                  value: _notifyMissedMedication,
                  onChanged: (value) {
                    setState(() {
                      _notifyMissedMedication = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            widget.guardian == null ? 'Add' : 'Save',
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _GuardianFormResult(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        relationship: _relationshipController.text.trim(),
        role: _role,
        notifyMissedMedication: _notifyMissedMedication,
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