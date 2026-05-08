import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/session/data/session_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

/// Raw Firebase auth stream. Used in the router to drive redirects.
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Derived UserModel from Firestore. This is what the rest of the app reads.
/// When the Firebase auth user changes, this re-subscribes to the new UID's
/// Firestore document, so role and pseudonym stay current without a re-login.
final currentUserModelProvider = StreamProvider<UserModel?>((ref) {
  final authAsync = ref.watch(firebaseAuthStateProvider);
  final user = authAsync.valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchCurrentUser(user.uid);
});
