import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Wraps FirebaseAuth + the user's profile document. The previous
/// `AuthService` had no password-reset method and never wrote a full name
/// anywhere, so signup collected a name the app then had nowhere to show.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp({
  required String fullName,
  required String email,
  required String password,
  required String role,
}) async {
  final credential = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  await credential.user?.updateDisplayName(fullName);

  await _firestore.collection('users').doc(credential.user!.uid).set({
    'fullName': fullName,
    'email': email,
    'role': role,
    'createdAt': FieldValue.serverTimestamp(),
  });

  return credential;
}

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  /// Updates the display name in both FirebaseAuth and the profile document.
  Future<void> updateFullName(String fullName) async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    await user.updateDisplayName(fullName);
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({'fullName': fullName}, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }
}
