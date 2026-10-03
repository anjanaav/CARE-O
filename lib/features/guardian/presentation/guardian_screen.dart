import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/state_views.dart';
import '../data/guardian_repository.dart';

class GuardianScreen extends StatefulWidget {
  const GuardianScreen({super.key});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  final _repository = GuardianRepository();

  Future<void> _callGuardian(Guardian guardian) async {
    final phoneUri = Uri.parse('tel:${guardian.phone}');
    final launched = await launchUrl(phoneUri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't start a call to ${guardian.name}.")),
      );
    }
  }

  void _showGuardianDialog({Guardian? existing}) {
    final nameController = TextEditingController(text: existing?.name);
    final phoneController = TextEditingController(text: existing?.phone);
    final emailController = TextEditingController(text: existing?.email);
    final relationshipController =
        TextEditingController(text: existing?.relationship);
    final formKey = GlobalKey<FormState>();

    GuardianRole role = existing?.role ?? GuardianRole.familyMember;
    bool notifyMedicationReminders = existing?.notifyMedicationReminders ?? false;
    bool notifyMissedMedication = existing?.notifyMissedMedication ?? false;
    bool notifyEmergencyAlerts = existing?.notifyEmergencyAlerts ?? false;
    bool shareWellnessSummary = existing?.shareWellnessSummary ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(existing == null ? 'Add to Family & Care Circle' : 'Edit Member'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: nameController,
                        label: 'Name',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: phoneController,
                        label: 'Phone number',
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a phone number'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: emailController,
                        label: 'Email (optional)',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: relationshipController,
                        label: 'Relationship (e.g. Daughter, Son, Friend)',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Role', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<GuardianRole>(
                        value: role,
                        items: GuardianRole.values
                            .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setStateDialog(() => role = value);
                        },
                      ),
                      if (role == GuardianRole.primaryGuardian)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            'Only one person can be your Primary Guardian. '
                            'Setting this will move anyone currently in that role to "Guardian".',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Notify this person about',
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        'Nothing is shared unless you turn it on here.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Medication reminders'),
                        value: notifyMedicationReminders,
                        onChanged: (v) =>
                            setStateDialog(() => notifyMedicationReminders = v ?? false),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Missed medication alerts'),
                        value: notifyMissedMedication,
                        onChanged: (v) =>
                            setStateDialog(() => notifyMissedMedication = v ?? false),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Emergency alerts'),
                        value: notifyEmergencyAlerts,
                        onChanged: (v) =>
                            setStateDialog(() => notifyEmergencyAlerts = v ?? false),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Daily wellness summary'),
                        value: shareWellnessSummary,
                        onChanged: (v) =>
                            setStateDialog(() => shareWellnessSummary = v ?? false),
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
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  if (existing == null) {
                    await _repository.addGuardian(
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      email: emailController.text.trim().isEmpty
                          ? null
                          : emailController.text.trim(),
                      relationship: relationshipController.text.trim(),
                      role: role,
                      notifyMedicationReminders: notifyMedicationReminders,
                      notifyMissedMedication: notifyMissedMedication,
                      notifyEmergencyAlerts: notifyEmergencyAlerts,
                      shareWellnessSummary: shareWellnessSummary,
                    );
                  } else {
                    await _repository.updateGuardian(
                      Guardian(
                        id: existing.id,
                        name: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        email: emailController.text.trim().isEmpty
                            ? null
                            : emailController.text.trim(),
                        relationship: relationshipController.text.trim(),
                        role: role,
                        notifyMedicationReminders: notifyMedicationReminders,
                        notifyMissedMedication: notifyMissedMedication,
                        notifyEmergencyAlerts: notifyEmergencyAlerts,
                        shareWellnessSummary: shareWellnessSummary,
                      ),
                    );
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Text(existing == null ? 'Add' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family & Care Circle')),
      body: StreamBuilder<List<Guardian>>(
        stream: _repository.watchGuardians(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const AppErrorState(
              message: "We couldn't load your family and care circle. "
                  'Please check your connection and try again.',
            );
          }
          if (!snapshot.hasData) return const LoadingState();
          final guardians = snapshot.data!;

          if (guardians.isEmpty) {
            return EmptyState(
              icon: Icons.diversity_3_outlined,
              title: 'No one in your circle yet',
              message:
                  'Add a trusted family member, guardian, or caregiver so you can '
                  'reach them quickly and choose what to share with them.',
              actionLabel: 'Add Member',
              onAction: () => _showGuardianDialog(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: guardians.length,
            itemBuilder: (context, index) {
              final guardian = guardians[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            child: Text(
                              guardian.name.isNotEmpty
                                  ? guardian.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(guardian.name,
                                          style: Theme.of(context).textTheme.titleMedium),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    _RoleChip(role: guardian.role),
                                  ],
                                ),
                                if (guardian.relationship.isNotEmpty)
                                  Text(guardian.relationship,
                                      style: Theme.of(context).textTheme.bodyMedium),
                                Text(guardian.phone,
                                    style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.call_outlined),
                            tooltip: 'Call',
                            onPressed: () => _callGuardian(guardian),
                          ),
                          IconButton(
                            icon: const Icon(Icons.videocam_outlined),
                            tooltip: 'Video call',
                            onPressed: () => context.push(
                              '/connect/video-call/${_repository.channelNameFor(guardian)}',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit',
                            onPressed: () => _showGuardianDialog(existing: guardian),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Remove',
                            onPressed: () async {
                              final confirmed = await showConfirmationDialog(
                                context,
                                title: 'Remove from Family & Care Circle?',
                                message: 'Remove ${guardian.name}?',
                                confirmLabel: 'Remove',
                                isDestructive: true,
                              );
                              if (confirmed) {
                                await _repository.deleteGuardian(guardian.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGuardianDialog(),
        tooltip: 'Add to Family & Care Circle',
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final GuardianRole role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmphasized =
        role == GuardianRole.primaryGuardian || role == GuardianRole.emergencyContact;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: isEmphasized
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.dividerColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isEmphasized ? theme.colorScheme.primary : null,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
