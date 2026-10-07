import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum GuardianRole {
  primaryGuardian,
  guardian,
  familyMember,
  caregiver,
  emergencyContact,
}

class Guardian {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String relationship;
  final GuardianRole role;
  final bool notifyMissedMedication;

  const Guardian({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.relationship,
    required this.role,
    required this.notifyMissedMedication,
  });

  factory Guardian.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return Guardian(
      id: document.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      relationship: data['relationship'] as String? ?? '',
      role: _roleFromString(data['role'] as String?),
      notifyMissedMedication:
          data['notifyMissedMedication'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'relationship': relationship,
      'role': role.name,
      'notifyMissedMedication': notifyMissedMedication,
    };
  }

  static GuardianRole _roleFromString(String? value) {
    switch (value) {
      case 'primaryGuardian':
        return GuardianRole.primaryGuardian;
      case 'familyMember':
        return GuardianRole.familyMember;
      case 'caregiver':
        return GuardianRole.caregiver;
      case 'emergencyContact':
        return GuardianRole.emergencyContact;
      case 'guardian':
      default:
        return GuardianRole.guardian;
    }
  }
}

class GuardianRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GuardianRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'You must be signed in.',
      );
    }

    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _guardians =>
      _firestore
          .collection('users')
          .doc(_uid)
          .collection('guardians');

  Stream<List<Guardian>> watchGuardians() {
    return _guardians
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Guardian.fromFirestore)
              .toList(),
        );
  }

  Future<String> addGuardian({
    required String name,
    String phone = '',
    String email = '',
    String relationship = '',
    GuardianRole role = GuardianRole.guardian,
    bool notifyMissedMedication = true,
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Guardian name cannot be empty.');
    }

    final existingPrimary = role == GuardianRole.primaryGuardian;

    if (existingPrimary) {
      await _clearExistingPrimaryGuardian();
    }

    final document = await _guardians.add({
      'name': trimmedName,
      'phone': phone.trim(),
      'email': email.trim(),
      'relationship': relationship.trim(),
      'role': role.name,
      'notifyMissedMedication': notifyMissedMedication,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Future<void> updateGuardian(
    String guardianId, {
    required String name,
    String phone = '',
    String email = '',
    String relationship = '',
    GuardianRole role = GuardianRole.guardian,
    bool notifyMissedMedication = true,
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Guardian name cannot be empty.');
    }

    if (role == GuardianRole.primaryGuardian) {
      await _clearExistingPrimaryGuardian(
        exceptGuardianId: guardianId,
      );
    }

    await _guardians.doc(guardianId).update({
      'name': trimmedName,
      'phone': phone.trim(),
      'email': email.trim(),
      'relationship': relationship.trim(),
      'role': role.name,
      'notifyMissedMedication': notifyMissedMedication,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteGuardian(String guardianId) async {
    await _guardians.doc(guardianId).delete();
  }

  Future<void> _clearExistingPrimaryGuardian({
    String? exceptGuardianId,
  }) async {
    final snapshot = await _guardians
        .where(
          'role',
          isEqualTo: GuardianRole.primaryGuardian.name,
        )
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final document in snapshot.docs) {
      if (document.id == exceptGuardianId) {
        continue;
      }

      batch.update(
        document.reference,
        {
          'role': GuardianRole.guardian.name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();
  }

  String channelNameFor(Guardian guardian) {
    final name = guardian.name.trim();

    if (name.isEmpty) {
      return 'CARE-O Guardian';
    }

    return 'CARE-O • $name';
  }
}