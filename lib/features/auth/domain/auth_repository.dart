import 'app_user.dart';

/// Authentication operations. Implementations throw [AuthFailure] on error.
abstract interface class AuthRepository {
  /// Emits the current user immediately, then on every sign-in, sign-out and
  /// profile change. `null` means signed out.
  Stream<AppUser?> authStateChanges();

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();
}
