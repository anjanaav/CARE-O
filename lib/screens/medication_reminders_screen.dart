import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/notifications/notification_preferences.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/state_views.dart';
import '../features/guardian/data/guardian_repository.dart';
import '../features/notifications/data/notification_outbox_repository.dart';
import '../notifications/medication_notifications.dart';

class MedicationRemindersScreen extends StatefulWidget {
  const MedicationRemindersScreen({super.key});

  @override
  State<MedicationRemindersScreen> createState() =>
      _MedicationRemindersScreenState();
}

class _MedicationRemindersScreenState
    extends State<MedicationRemindersScreen> {
  late final CollectionReference _medicationsRef = FirebaseFirestore
      .instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('medication_reminders');

  Timer? _missedMedicationTimer;

  @override
  void initState() {
    super.initState();

    _checkForMissedMedications();

    _missedMedicationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkForMissedMedications(),
    );
  }

  @override
  void dispose() {
    _missedMedicationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkForMissedMedications() async {
    try {
      final alertsEnabled =
          await NotificationPreferencesController
              .readMissedMedicationAlertsEnabled();

      if (!alertsEnabled) return;

      final now = DateTime.now();
      const grace = Duration(minutes: 30);

      final snapshot = await _medicationsRef.get();

      final overdue = snapshot.docs.where((doc) {
        final data =
            doc.data() as Map<String, dynamic>?;

        if (data == null) return false;
        if (data['confirmedByUser'] == true) return false;
        if (data['missedAlertQueued'] == true) return false;

        final reminderTime =
            (data['reminderTime'] as Timestamp?)?.toDate();

        if (reminderTime == null) return false;

        return now.difference(reminderTime) > grace;
      }).toList();

      if (overdue.isEmpty) return;

      final guardians =
          await GuardianRepository().watchGuardians().first;

      if (guardians.isEmpty) return;

      final outbox = NotificationOutboxRepository();

      for (final doc in overdue) {
        final data =
            doc.data() as Map<String, dynamic>;

        await outbox.enqueueMissedMedicationAlert(
          medicationName:
              data['medicationName'] as String? ??
                  'a medication',
          reminderTime:
              (data['reminderTime'] as Timestamp).toDate(),
          guardians: guardians,
        );

        await doc.reference.update({
          'missedAlertQueued': true,
        });
      }
    } catch (e) {
      debugPrint(
        'Error checking missed medications: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Reminders'),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _medicationsRef
            .orderBy('reminderTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const LoadingState();
          }

          if (snapshot.hasError) {
            return const AppErrorState(
              message:
                  "We couldn't load your medication reminders.",
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return EmptyState(
              icon: Icons.medication_outlined,
              title: 'No medication reminders yet',
              message:
                  'Add one to get started with daily reminders.',
              actionLabel: 'Add Reminder',
              onAction: _showAddReminderDialog,
            );
          }

          final reminders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: 100,
            ),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];

              final data =
                  reminder.data()
                      as Map<String, dynamic>?;

              final reminderTimestamp =
                  data?['reminderTime'] as Timestamp?;

              if (reminderTimestamp == null) {
                return const SizedBox.shrink();
              }

              final reminderTime =
                  reminderTimestamp.toDate();

              final medicationName =
                  data?['medicationName']
                          ?.toString() ??
                      'Medication';

              final dosageSchedule =
                  data?['dosageSchedule']
                          ?.toString() ??
                      'Not specified';

              final isConfirmed =
                  data?['confirmedByUser'] == true;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: colorScheme
                                  .primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.medication_outlined,
                              color: colorScheme
                                  .onPrimaryContainer,
                              size: 25,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medicationName,
                                  style: theme
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                    fontWeight:
                                        FontWeight.w700,
                                    color: colorScheme
                                        .onSurface,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  DateFormat.jm().format(
                                    reminderTime,
                                  ),
                                  style: theme
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                    color: colorScheme
                                        .primary,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  'Dosage: $dosageSchedule',
                                  style: theme
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                    color: colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            tooltip: 'Edit reminder',
                            icon: const Icon(
                              Icons.edit_outlined,
                            ),
                            color: colorScheme
                                .onSurfaceVariant,
                            onPressed: () =>
                                _showEditReminderDialog(
                              reminder,
                            ),
                          ),

                          IconButton(
                            tooltip: 'Delete reminder',
                            icon: Icon(
                              Icons.delete_outline,
                              color: colorScheme.error,
                            ),
                            onPressed: () =>
                                _deleteReminder(
                              reminder.id,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: isConfirmed
                            ? OutlinedButton.icon(
                                onPressed: () =>
                                    _undoConfirmation(
                                  reminder.id,
                                ),
                                icon: const Icon(
                                  Icons.undo,
                                ),
                                label:
                                    const Text('Undo'),
                                style:
                                    OutlinedButton
                                        .styleFrom(
                                  foregroundColor:
                                      colorScheme.error,
                                  side: BorderSide(
                                    color:
                                        colorScheme.error,
                                  ),
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: () =>
                                    _confirmMedication(
                                  reminder.id,
                                  reminderTime,
                                ),
                                icon: const Icon(
                                  Icons.check,
                                ),
                                label: const Text(
                                  'Confirm Medication',
                                ),
                                style:
                                    FilledButton.styleFrom(
                                  backgroundColor:
                                      colorScheme
                                          .primary,
                                  foregroundColor:
                                      colorScheme
                                          .onPrimary,
                                ),
                              ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            isConfirmed
                                ? Icons.check_circle
                                : Icons.schedule,
                            size: 17,
                            color: isConfirmed
                                ? colorScheme.primary
                                : colorScheme
                                    .onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isConfirmed
                                ? 'Medication confirmed'
                                : 'Waiting for confirmation',
                            style: theme
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color: isConfirmed
                                  ? colorScheme.primary
                                  : colorScheme
                                      .onSurfaceVariant,
                              fontWeight:
                                  FontWeight.w600,
                            ),
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

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        tooltip: 'Add medication reminder',
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
      ),
    );
  }

  Future<void> _undoConfirmation(String docId) async {
    try {
      await _medicationsRef.doc(docId).update({
        'confirmedByUser': false,
        'confirmationTimestamp': null,
      });
    } catch (e) {
      debugPrint(
        'Error undoing medication confirmation: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Unable to undo confirmation.'),
        ),
      );
    }
  }

  Future<void> _confirmMedication(
    String docId,
    DateTime currentReminderTime,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Medication'),
          content: const Text(
            'Did you take the medicine?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false),
              child: Text(
                'No',
                style: TextStyle(
                  color: colorScheme.error,
                ),
              ),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final nextReminderTime =
          currentReminderTime.add(
        const Duration(days: 1),
      );

      await _medicationsRef.doc(docId).update({
        'confirmedByUser': true,
        'confirmationTimestamp':
            DateTime.now().toIso8601String(),
        'reminderTime':
            Timestamp.fromDate(nextReminderTime),
        'missedAlertQueued': false,
      });

      final data =
          (await _medicationsRef.doc(docId).get())
              .data() as Map<String, dynamic>?;

      await MedicationNotificationService.instance
          .scheduleReminder(
        reminderDocId: docId,
        medicationName:
            data?['medicationName'] ??
                'your medication',
        reminderTime: nextReminderTime,
      );
    } catch (e) {
      debugPrint(
        'Error confirming medication: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Unable to confirm medication.'),
        ),
      );
    }
  }

  Future<void> _deleteReminder(String docId) async {
    try {
      await MedicationNotificationService.instance
          .cancelReminder(docId);

      await _medicationsRef.doc(docId).delete();
    } catch (e) {
      debugPrint(
        'Error deleting medication reminder: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Unable to delete reminder.'),
        ),
      );
    }
  }

  void _showAddReminderDialog() {
    _showReminderDialog();
  }

  void _showEditReminderDialog(
    DocumentSnapshot reminder,
  ) {
    _showReminderDialog(
      reminder: reminder,
    );
  }

  void _showReminderDialog({
    DocumentSnapshot? reminder,
  }) {
    String medicationName =
        reminder?['medicationName'] ?? '';

    TimeOfDay selectedTime = reminder != null
        ? TimeOfDay.fromDateTime(
            (reminder['reminderTime']
                    as Timestamp)
                .toDate(),
          )
        : TimeOfDay.now();

    String dosageSchedule =
        reminder?['dosageSchedule'] ?? '1-0-1';

    final formKey =
        GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme =
            Theme.of(dialogContext);
        final colorScheme =
            theme.colorScheme;

        return StatefulBuilder(
          builder: (
            context,
            setStateDialog,
          ) {
            return AlertDialog(
              title: Text(
                reminder == null
                    ? 'Add Medication Reminder'
                    : 'Edit Medication Reminder',
              ),

              content:
                  SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue:
                            medicationName,
                        textCapitalization:
                            TextCapitalization
                                .sentences,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Medication Name',
                          hintText:
                              'Enter medication name',
                          prefixIcon: Icon(
                            Icons.medication_outlined,
                          ),
                        ),
                        validator:
                            (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Please enter a medication name';
                          }

                          return null;
                        },
                        onChanged:
                            (value) {
                          medicationName =
                              value.trim();
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color: colorScheme
                              .surfaceContainerHighest,
                          borderRadius:
                              BorderRadius
                                  .circular(12),
                          border:
                              Border.all(
                            color: colorScheme
                                .outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .access_time,
                              color:
                                  colorScheme
                                      .primary,
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child: Text(
                                'Time: ${selectedTime.format(context)}',
                                style: theme
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                  color:
                                      colorScheme
                                          .onSurface,
                                  fontWeight:
                                      FontWeight
                                          .w500,
                                ),
                              ),
                            ),

                            TextButton(
                              onPressed:
                                  () async {
                                final pickedTime =
                                    await showTimePicker(
                                  context:
                                      context,
                                  initialTime:
                                      selectedTime,
                                );

                                if (pickedTime ==
                                    null) {
                                  return;
                                }

                                setStateDialog(
                                  () {
                                    selectedTime =
                                        pickedTime;
                                  },
                                );
                              },
                              child:
                                  const Text(
                                'Select',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            dosageSchedule,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Dosage Schedule',
                          prefixIcon: Icon(
                            Icons
                                .format_list_numbered,
                          ),
                        ),
                        items: const [
                          '1-0-1',
                          '0-1-0',
                          '1-1-1',
                          '0-0-1',
                          '1-1-0',
                        ].map(
                          (value) {
                            return DropdownMenuItem<
                                String>(
                              value: value,
                              child:
                                  Text(value),
                            );
                          },
                        ).toList(),
                        onChanged:
                            (newValue) {
                          if (newValue ==
                              null) {
                            return;
                          }

                          setStateDialog(
                            () {
                              dosageSchedule =
                                  newValue;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(
                    dialogContext,
                  ).pop(),
                  child:
                      const Text('Cancel'),
                ),

                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!
                        .validate()) {
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop();

                    _saveReminder(
                      medicationName,
                      selectedTime,
                      dosageSchedule,
                      reminder?.id,
                    );
                  },
                  child: Text(
                    reminder == null
                        ? 'Add'
                        : 'Update',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveReminder(
    String medicationName,
    TimeOfDay selectedTime,
    String dosageSchedule,
    String? docId,
  ) async {
    if (medicationName.trim().isEmpty) {
      return;
    }

    final now = DateTime.now();

    DateTime reminderDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // If today's selected time has already passed,
    // schedule it for tomorrow.
    if (docId == null &&
        reminderDateTime.isBefore(now)) {
      reminderDateTime =
          reminderDateTime.add(
        const Duration(days: 1),
      );
    }

    try {
      if (docId == null) {
        final newDoc =
            await _medicationsRef.add({
          'medicationName':
              medicationName.trim(),
          'reminderTime':
              Timestamp.fromDate(
            reminderDateTime,
          ),
          'dosageSchedule':
              dosageSchedule,
          'confirmedByUser': false,
          'missedAlertQueued': false,
          'createdAt':
              FieldValue.serverTimestamp(),
        });

        await MedicationNotificationService
            .instance
            .scheduleReminder(
          reminderDocId: newDoc.id,
          medicationName:
              medicationName.trim(),
          reminderTime:
              reminderDateTime,
        );
      } else {
        await _medicationsRef
            .doc(docId)
            .update({
          'medicationName':
              medicationName.trim(),
          'reminderTime':
              Timestamp.fromDate(
            reminderDateTime,
          ),
          'dosageSchedule':
              dosageSchedule,
          'confirmedByUser': false,
          'missedAlertQueued': false,
        });

        await MedicationNotificationService
            .instance
            .scheduleReminder(
          reminderDocId: docId,
          medicationName:
              medicationName.trim(),
          reminderTime:
              reminderDateTime,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            docId == null
                ? 'Medication reminder added.'
                : 'Medication reminder updated.',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Error saving medication reminder: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save medication reminder.',
          ),
        ),
      );
    }
  }
}