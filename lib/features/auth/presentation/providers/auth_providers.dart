import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Drives the router redirect: null = signed out, User = signed in.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// The signed-in user's profile document. Invalidate after editing.
final profileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) {
  // Re-fetch when the signed-in account changes.
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).fetchProfile();
});
