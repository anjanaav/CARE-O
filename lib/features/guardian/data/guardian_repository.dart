import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A person in the senior user's Family & Care Circle. Every member has a
/// role, which determines how they're labeled in the UI, and a set of
/// notification permissions the senior user controls explicitly — nobody
/// is opted in to anything by default.
enum GuardianRole {
  primaryGuardian,
  guardian,
  familyMember,
  caregiver,
  emergencyContact;

  String get label {
    switch (this) {
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

  static GuardianRole fromName(String? name) {
    return GuardianRole.values.firstWhere(
      (r) => r.name == name,
      orElse: () => GuardianRole.familyMember,
    );
  }
}

class Guardian {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String relationship;
  final GuardianRole role;

  // Notification permissions. All default to false — the senior user
  // must explicitly turn each one on for a given contact. This is what
  // Phase 0/rules calls "permission-based sharing": nobody is notified
  // just because they were added.
  final bool notifyMedicationReminders;
  final bool notifyMissedMedication;
  final bool notifyEmergencyAlerts;
  final bool shareWellnessSummary;

  Guardian({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.relationship,
    this.role = GuardianRole.familyMember,
    this.notifyMedicationReminders = false,
    this.notifyMissedMedication = false,
    this.notifyEmergencyAlerts = false,
    this.shareWellnessSummary = false,
  });

  bool get isPrimaryGuardian => role == GuardianRole.primaryGuardian;
  bool get isEmergencyContact => role == GuardianRole.emergencyContact;

  factory Guardian.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Guardian(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] as String?,
      relationship: data['relationship'] ?? '',
      role: GuardianRole.fromName(data['role'] as String?),
      notifyMedicationReminders: data['notifyMedicationReminders'] ?? false,
      notifyMissedMedication: data['notifyMissedMedication'] ?? false,
      notifyEmergencyAlerts: data['notifyEmergencyAlerts'] ?? false,
      shareWellnessSummary: data['shareWellnessSummary'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'email': email,
        'relationship': relationship,
        'role': role.name,
        'notifyMedicationReminders': notifyMedicationReminders,
        'notifyMissedMedication': notifyMissedMedication,
        'notifyEmergencyAlerts': notifyEmergencyAlerts,
        'shareWellnessSummary': shareWellnessSummary,
      };
}

/// Real contact management, replacing the previous "Guardian Control"
/// screen which had no way to add/view/contact an actual guardian and the
/// "Social Connections" screen which only had one button that joined a
/// hardcoded shared video channel ("careo") for every user in the app.
///
/// Every notification permission on a Guardian document defaults to false
/// and is only ever changed by an explicit action from this screen — see
/// section 16 ("Family Permissions") of the product spec. There is
/// currently no backend that actually reads these flags to decide who to
/// notify (that requires server infrastructure — see Phase 4 notes); this
/// repository is the source of truth those notifications will consult
/// once that backend exists, not a promise that notifications are already
/// being sent.
class GuardianRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GuardianRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference get _collection => _firestore
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('guardians');

  Stream<List<Guardian>> watchGuardians() {
    return _collection.orderBy('name').snapshots().map(
          (snap) => snap.docs.map(Guardian.fromDoc).toList(),
        );
  }

  Future<void> addGuardian({
    required String name,
    required String phone,
    String? email,
    required String relationship,
    GuardianRole role = GuardianRole.familyMember,
    bool notifyMedicationReminders = false,
    bool notifyMissedMedication = false,
    bool notifyEmergencyAlerts = false,
    bool shareWellnessSummary = false,
  }) async {
    final docRef = _collection.doc();
    if (role == GuardianRole.primaryGuardian) {
      await _clearExistingPrimaryGuardian();
    }
    await docRef.set({
      'name': name,
      'phone': phone,
      'email': email,
      'relationship': relationship,
      'role': role.name,
      'notifyMedicationReminders': notifyMedicationReminders,
      'notifyMissedMedication': notifyMissedMedication,
      'notifyEmergencyAlerts': notifyEmergencyAlerts,
      'shareWellnessSummary': shareWellnessSummary,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGuardian(Guardian guardian) async {
    if (guardian.role == GuardianRole.primaryGuardian) {
      await _clearExistingPrimaryGuardian(exceptId: guardian.id);
    }
    await _collection.doc(guardian.id).update(guardian.toMap());
  }

  Future<void> deleteGuardian(String id) {
    return _collection.doc(id).delete();
  }

  /// Only one member can hold the Primary Guardian role at a time. When a
  /// new member is promoted to it, everyone else is demoted to plain
  /// "Guardian" so the senior user never has an ambiguous "who's actually
  /// primary" state.
  Future<void> _clearExistingPrimaryGuardian({String? exceptId}) async {
    final existing = await _collection
        .where('role', isEqualTo: GuardianRole.primaryGuardian.name)
        .get();
    final batch = _firestore.batch();
    for (final doc in existing.docs) {
      if (doc.id == exceptId) continue;
      batch.update(doc.reference, {'role': GuardianRole.guardian.name});
    }
    await batch.commit();
  }

  /// Deterministic per-contact channel name so each guardian gets their own
  /// private call room instead of everyone sharing one hardcoded channel.
  String channelNameFor(Guardian guardian) {
    final uid = _auth.currentUser!.uid;
    final ids = [uid, guardian.id]..sort();
    return 'careo_${ids.join('_')}';
  }
}
