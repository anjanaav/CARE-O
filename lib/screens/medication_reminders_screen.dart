import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/state_views.dart';
import '../core/notifications/notification_preferences.dart';
import '../notifications/medication_notifications.dart';
import '../features/guardian/data/guardian_repository.dart';
import '../features/notifications/data/notification_outbox_repository.dart';

class MedicationRemindersScreen extends StatefulWidget {
  const MedicationRemindersScreen({super.key});

  @override
  _MedicationRemindersScreenState createState() =>
      _MedicationRemindersScreenState();
}

class _MedicationRemindersScreenState extends State<MedicationRemindersScreen> {
  // Scoped under the signed-in user, matching firestore.rules — the
  // previous version queried a single global `medication_reminder`
  // collection shared by every user in the app.
  late final CollectionReference _medicationsRef = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('medication_reminders');

  Timer? _missedMedicationTimer;

  @override
  void initState() {
    super.initState();
    // Check once when the screen opens, then periodically while it's open.
    // A reminder that's overdue while the app is closed will be caught the
    // next time this screen is visited — there is no background job doing
    // this yet (that would need the same Cloud Function described in
    // features/notifications/README.md).
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

  /// Finds reminders that are overdue by more than 30 minutes and haven't
  /// been confirmed or already flagged, and queues a missed-medication
  /// alert for any guardian who has consented to receive one (see
  /// NotificationOutboxRepository). Each reminder is only ever queued
  /// once, via the `missedAlertQueued` flag, so re-running this on a timer
  /// doesn't spam the outbox.
  Future<void> _checkForMissedMedications() async {
    final alertsEnabled =
        await NotificationPreferencesController.readMissedMedicationAlertsEnabled();
    if (!alertsEnabled) return;

    final now = DateTime.now();
    const grace = Duration(minutes: 30);

    final snapshot = await _medicationsRef.get();
    final overdue = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;
      if (data['confirmedByUser'] == true) return false;
      if (data['missedAlertQueued'] == true) return false;
      final reminderTime = (data['reminderTime'] as Timestamp?)?.toDate();
      if (reminderTime == null) return false;
      return now.difference(reminderTime) > grace;
    }).toList();

    if (overdue.isEmpty) return;

    final guardians = await GuardianRepository().watchGuardians().first;
    if (guardians.isEmpty) return;

    final outbox = NotificationOutboxRepository();
    for (final doc in overdue) {
      final data = doc.data() as Map<String, dynamic>;
      await outbox.enqueueMissedMedicationAlert(
        medicationName: data['medicationName'] as String? ?? 'a medication',
        reminderTime: (data['reminderTime'] as Timestamp).toDate(),
        guardians: guardians,
      );
      await doc.reference.update({'missedAlertQueued': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication Reminders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _medicationsRef.orderBy('reminderTime').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }

          if (snapshot.hasError) {
            return const AppErrorState(
              message: "We couldn't load your medication reminders.",
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return EmptyState(
              icon: Icons.medication_outlined,
              title: 'No medication reminders yet',
              message: 'Add one to get started with daily reminders.',
              actionLabel: 'Add Reminder',
              onAction: _showAddReminderDialog,
            );
          }

          var reminders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              var reminder = reminders[index];
              DateTime reminderTime =
                  (reminder['reminderTime'] as Timestamp).toDate();
              final data = reminder.data() as Map<String, dynamic>?;
              final isConfirmed = data?['confirmedByUser'] ?? false;
              final theme = Theme.of(context);

              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reminder['medicationName'],
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        "${DateFormat.jm().format(reminderTime)} · Dosage ${reminder['dosageSchedule']}",
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: isConfirmed
                                ? OutlinedButton(
                                    onPressed: () =>
                                        _undoConfirmation(reminder.id),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(color: AppColors.error),
                                      minimumSize: const Size.fromHeight(44),
                                    ),
                                    child: const Text("Undo"),
                                  )
                                : ElevatedButton(
                                    onPressed: () => _confirmMedication(
                                        reminder.id,
                                        (reminder['reminderTime'] as Timestamp)
                                            .toDate()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(44),
                                    ),
                                    child: const Text("Confirm"),
                                  ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit',
                            onPressed: () => _showEditReminderDialog(reminder),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                            tooltip: 'Delete',
                            onPressed: () => _deleteReminder(reminder.id),
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
        onPressed: _showAddReminderDialog,
        tooltip: 'Add Medication Reminder',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _undoConfirmation(String docId) async {
    await _medicationsRef.doc(docId).update({
      'confirmedByUser': false,
      'confirmationTimestamp': null, // Remove timestamp
    });
  }

  void _confirmMedication(String docId, DateTime currentReminderTime) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Medication"),
        content: const Text("Did you take the medicine?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      DateTime nextReminderTime =
          currentReminderTime.add(const Duration(days: 1));

      await _medicationsRef.doc(docId).update({
        'confirmedByUser': true,
        'confirmationTimestamp': DateTime.now().toIso8601String(),
        'reminderTime':
            Timestamp.fromDate(nextReminderTime), // Move to next day
        'missedAlertQueued': false,
      });

      final data = (await _medicationsRef.doc(docId).get()).data()
          as Map<String, dynamic>?;
      await MedicationNotificationService.instance.scheduleReminder(
        reminderDocId: docId,
        medicationName: data?['medicationName'] ?? 'your medication',
        reminderTime: nextReminderTime,
      );
    }
  }

  void _deleteReminder(String docId) async {
    await MedicationNotificationService.instance.cancelReminder(docId);
    await _medicationsRef.doc(docId).delete();
  }

  void _showAddReminderDialog() {
    _showReminderDialog();
  }

  void _showEditReminderDialog(DocumentSnapshot reminder) {
    _showReminderDialog(reminder: reminder);
  }

  void _showReminderDialog({DocumentSnapshot? reminder}) {
    String medicationName = reminder?['medicationName'] ?? "";
    TimeOfDay selectedTime = reminder != null
        ? TimeOfDay.fromDateTime(
            (reminder['reminderTime'] as Timestamp).toDate())
        : TimeOfDay.now();
    String dosageSchedule = reminder?['dosageSchedule'] ?? "1-0-1";
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(reminder == null
                  ? "Add Medication Reminder"
                  : "Edit Medication Reminder"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: medicationName,
                      decoration:
                          const InputDecoration(labelText: "Medication Name"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a medication name";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        medicationName = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text("Time: ${selectedTime.format(context)}"),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (pickedTime != null) {
                              setStateDialog(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                          child: const Text("Select Time"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: dosageSchedule,
                      decoration:
                          const InputDecoration(labelText: "Dosage Schedule"),
                      items: ["1-0-1", "0-1-0", "1-1-1", "0-0-1", "1-1-0"]
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setStateDialog(() {
                          dosageSchedule = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () => _saveReminder(medicationName, selectedTime,
                      dosageSchedule, reminder?.id),
                  child: Text(reminder == null ? "Add" : "Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveReminder(String medicationName, TimeOfDay selectedTime,
      String dosageSchedule, String? docId) async {
    if (medicationName.isEmpty) return;

    DateTime now = DateTime.now();
    DateTime reminderDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (docId == null) {
      final newDoc = await _medicationsRef.add({
        'medicationName': medicationName,
        'reminderTime': Timestamp.fromDate(reminderDateTime),
        'dosageSchedule': dosageSchedule,
      });
      await MedicationNotificationService.instance.scheduleReminder(
        reminderDocId: newDoc.id,
        medicationName: medicationName,
        reminderTime: reminderDateTime,
      );
    } else {
      await _medicationsRef.doc(docId).update({
        'medicationName': medicationName,
        'reminderTime': Timestamp.fromDate(reminderDateTime),
        'dosageSchedule': dosageSchedule,
        'missedAlertQueued': false,
      });
      await MedicationNotificationService.instance.scheduleReminder(
        reminderDocId: docId,
        medicationName: medicationName,
        reminderTime: reminderDateTime,
      );
    }

    Navigator.of(context).pop();
  }
}
