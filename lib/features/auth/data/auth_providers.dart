import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import 'firebase_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

/// The signed-in user, or `null`. Waits for Firebase before subscribing.
/// Firebase Auth persists the session, so a restarted app emits the
/// previously signed-in user.
final authStateProvider = StreamProvider<AppUser?>((ref) async* {
  await ref.watch(firebaseInitProvider.future);
  yield* ref.watch(authRepositoryProvider).authStateChanges();
}, retry: (retryCount, error) => null);
