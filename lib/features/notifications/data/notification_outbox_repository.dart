import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../guardian/data/guardian_repository.dart';

/// Queues notifications destined for the Family & Care Circle.
///
/// This is intentionally an "outbox", not a notification sender. The app
/// has no server component, so it cannot itself deliver an SMS, email, or
/// push notification to someone else's phone — doing that safely requires
/// a backend with its own credentials, which does not exist yet. Writing
/// a queue entry here is the correct, honest stopping point on the client:
/// it records exactly what should be sent and to whom, in a shape a
/// Cloud Function can pick up and deliver once that backend exists. See
/// features/notifications/README.md for exactly what that function needs
/// to do.
///
/// Every entry already reflects consent at write time: only guardians who
/// have the matching permission turned on (see [Guardian] in
/// guardian_repository.dart) are ever added to [guardianIds].
class NotificationOutboxRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationOutboxRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference get _queue => _firestore
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('notification_queue');

  /// Queues a "missed medication" alert for every guardian in [guardians]
  /// who has consented to `notifyMissedMedication`. Does nothing (writes
  /// no document) if no guardian has consented — there is no reason to
  /// queue an alert nobody has agreed to receive.
  Future<void> enqueueMissedMedicationAlert({
    required String medicationName,
    required DateTime reminderTime,
    required List<Guardian> guardians,
  }) async {
    final consentedGuardianIds = guardians
        .where((g) => g.notifyMissedMedication)
        .map((g) => g.id)
        .toList();

    if (consentedGuardianIds.isEmpty) return;

    await _queue.add({
      'type': 'missed_medication',
      'medicationName': medicationName,
      'reminderTime': Timestamp.fromDate(reminderTime),
      'guardianIds': consentedGuardianIds,
      'createdAt': FieldValue.serverTimestamp(),
      'delivered': false,
    });
  }
}
