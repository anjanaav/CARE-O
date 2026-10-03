import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'core/widgets/state_views.dart';

class MedicationIntakeScreen extends StatelessWidget {
  // Scoped under the signed-in user, matching firestore.rules — the
  // previous version queried a single global `medication_reminder`
  // collection shared by every user in the app.
  late final CollectionReference _medicationsRef = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('medication_reminders');

  MedicationIntakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication Intake')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _medicationsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }

          if (snapshot.hasError) {
            return const AppErrorState(
              message: "We couldn't load your medication intake history.",
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const EmptyState(
              icon: Icons.medication_liquid_outlined,
              title: 'No medication data yet',
              message: 'Intake history will show up here once you add reminders.',
            );
          }

          var medications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, index) {
              var medication = medications[index];
              var data = medication.data() as Map<String, dynamic>;

              bool confirmed = data['confirmedByUser'] ?? false;
              String medicationName = data['medicationName'] ?? "Unknown";
              String dosageSchedule = data['dosageSchedule'] ?? "N/A";

              // ✅ Fix: Convert String Timestamp to DateTime safely
              DateTime? confirmationDateTime;
              if (data['confirmationTimestamp'] is Timestamp) {
                confirmationDateTime =
                    (data['confirmationTimestamp'] as Timestamp).toDate();
              } else if (data['confirmationTimestamp'] is String) {
                try {
                  confirmationDateTime =
                      DateTime.parse(data['confirmationTimestamp']);
                } catch (e) {
                  confirmationDateTime = null;
                }
              }

              DateTime? reminderDateTime;
              if (data['reminderTime'] is Timestamp) {
                reminderDateTime = (data['reminderTime'] as Timestamp).toDate();
              } else if (data['reminderTime'] is String) {
                try {
                  reminderDateTime = DateTime.parse(data['reminderTime']);
                } catch (e) {
                  reminderDateTime = null;
                }
              }

              // Format timestamps for display
              String formattedConfirmationTime = confirmationDateTime != null
                  ? DateFormat('dd MMM yyyy, hh:mm a')
                      .format(confirmationDateTime)
                  : "Not Taken";

              String formattedReminderTime = reminderDateTime != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(reminderDateTime)
                  : "No Reminder Set";

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(medicationName,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Dosage: $dosageSchedule"),
                      Text("Reminder: $formattedReminderTime"),
                      Text("Status: ${confirmed ? '✅ Taken' : '❌ Not Taken'}"),
                    ],
                  ),
                  trailing: Text(
                    confirmed
                        ? "Taken at:\n$formattedConfirmationTime"
                        : "Not Taken Yet",
                    textAlign: TextAlign.right,
                    style:
                        TextStyle(color: confirmed ? Colors.green : Colors.red),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
