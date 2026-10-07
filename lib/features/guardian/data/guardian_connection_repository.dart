import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GuardianConnectionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GuardianConnectionRepository({
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

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Creates a temporary connection code for a Senior account.
  ///
  /// The code is valid for 30 minutes and can be used once.
  Future<String> createGuardianCode() async {
    final seniorUid = _uid;

    final profile = await _users.doc(seniorUid).get();
    final profileData = profile.data();

    if (!profile.exists || profileData?['role'] != 'senior') {
      throw StateError(
        'Only Senior accounts can create guardian connection codes.',
      );
    }

    final code = await _createUniqueCode();

    await _firestore
        .collection('guardian_connection_codes')
        .doc(code)
        .set({
      'seniorUid': seniorUid,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 30)),
      ),
      'used': false,
    });

    return code;
  }

  /// Connects the currently logged-in Guardian to a Senior
  /// using the connection code.
  Future<void> connectUsingCode(String code) async {
    final guardianUid = _uid;

    final normalizedCode = code.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      throw ArgumentError('Please enter a connection code.');
    }

    final guardianProfile = await _users.doc(guardianUid).get();
    final guardianData = guardianProfile.data();

    if (!guardianProfile.exists || guardianData?['role'] != 'guardian') {
      throw StateError(
        'Only Guardian accounts can redeem a connection code.',
      );
    }

    final codeRef = _firestore
        .collection('guardian_connection_codes')
        .doc(normalizedCode);

    final codeSnapshot = await codeRef.get();

    if (!codeSnapshot.exists) {
      throw StateError('Invalid connection code.');
    }

    final codeData = codeSnapshot.data();

    if (codeData == null) {
      throw StateError('Invalid connection code.');
    }

    final seniorUid = codeData['seniorUid'] as String?;

    if (seniorUid == null || seniorUid.isEmpty) {
      throw StateError('This connection code is invalid.');
    }

    if (seniorUid == guardianUid) {
      throw StateError(
        'You cannot connect an account to itself.',
      );
    }

    if (codeData['used'] == true) {
      throw StateError(
        'This connection code has already been used.',
      );
    }

    final expiresAt = codeData['expiresAt'];

    if (expiresAt is Timestamp &&
        expiresAt.toDate().isBefore(DateTime.now())) {
      throw StateError(
        'This connection code has expired.',
      );
    }

    // Get Senior profile.
    final seniorSnapshot = await _users.doc(seniorUid).get();

    if (!seniorSnapshot.exists) {
      throw StateError(
        'The Senior account could not be found.',
      );
    }

    final seniorData = seniorSnapshot.data();

    if (seniorData == null || seniorData['role'] != 'senior') {
      throw StateError(
        'The selected account is not a Senior account.',
      );
    }

    // References on both sides of the relationship.
    final seniorGuardianRef = _users
        .doc(seniorUid)
        .collection('connected_guardians')
        .doc(guardianUid);

    final guardianSeniorRef = _users
        .doc(guardianUid)
        .collection('connected_seniors')
        .doc(seniorUid);

    final batch = _firestore.batch();

    // Senior → Guardian
   batch.set(
  seniorGuardianRef,
  {
    'guardianUid': guardianUid,
    'guardianName': guardianData?['fullName'] ?? '',
    'guardianEmail': guardianData?['email'] ?? '',
    'status': 'connected',
    'connectionCode': normalizedCode,
    'connectedAt': FieldValue.serverTimestamp(),
  },
  SetOptions(merge: true),
);

    // Guardian → Senior
    batch.set(
      guardianSeniorRef,
      {
        'seniorUid': seniorUid,
        'seniorName': seniorData['fullName'] ?? '',
        'seniorEmail': seniorData['email'] ?? '',
        'status': 'connected',
        'connectedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Mark code as used.
    batch.update(
      codeRef,
      {
        'used': true,
        'usedBy': guardianUid,
        'usedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  /// Returns all Seniors connected to the current Guardian.
  Stream<List<Map<String, dynamic>>> watchConnectedSeniors() {
    final guardianUid = _uid;

    return _users
        .doc(guardianUid)
        .collection('connected_seniors')
        .where(
          'status',
          isEqualTo: 'connected',
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs.map(
              (doc) {
                return {
                  'uid': doc.id,
                  ...doc.data(),
                };
              },
            ).toList();
          },
        );
  }

  /// Returns all Guardians connected to the current Senior.
  Stream<List<Map<String, dynamic>>> watchConnectedGuardians() {
    final seniorUid = _uid;

    return _users
        .doc(seniorUid)
        .collection('connected_guardians')
        .where(
          'status',
          isEqualTo: 'connected',
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs.map(
              (doc) {
                return {
                  'uid': doc.id,
                  ...doc.data(),
                };
              },
            ).toList();
          },
        );
  }

  /// Disconnects the current Guardian from a Senior.
  Future<void> disconnectSenior(String seniorUid) async {
    final guardianUid = _uid;

    final batch = _firestore.batch();

    batch.delete(
      _users
          .doc(guardianUid)
          .collection('connected_seniors')
          .doc(seniorUid),
    );

    batch.delete(
      _users
          .doc(seniorUid)
          .collection('connected_guardians')
          .doc(guardianUid),
    );

    await batch.commit();
  }

  /// Disconnects the current Senior from a Guardian.
  Future<void> disconnectGuardian(String guardianUid) async {
    final seniorUid = _uid;

    final batch = _firestore.batch();

    batch.delete(
      _users
          .doc(seniorUid)
          .collection('connected_guardians')
          .doc(guardianUid),
    );

    batch.delete(
      _users
          .doc(guardianUid)
          .collection('connected_seniors')
          .doc(seniorUid),
    );

    await batch.commit();
  }

  /// Generates a unique CARE-XXXXXXXX code.
  Future<String> _createUniqueCode() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      final code = _generateCode();

      final existing = await _firestore
          .collection('guardian_connection_codes')
          .doc(code)
          .get();

      if (!existing.exists) {
        return code;
      }
    }

    throw StateError(
      'Unable to generate a unique connection code. Please try again.',
    );
  }

  String _generateCode() {
    const characters =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    final random = Random.secure();

    final value = List.generate(
      8,
      (_) => characters[random.nextInt(characters.length)],
    ).join();

    return 'CARE-$value';
  }
}