import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_user.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> authStateChanges() =>
      // userChanges() also fires on profile updates such as the display name.
      _auth.userChanges().map((user) => user == null ? null : _toAppUser(user));

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(
        () => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) => _guard(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());
  });

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  static AppUser _toAppUser(User user) => AppUser(
    uid: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
  );

  static Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(mapAuthErrorCode(e.code));
    }
  }
}

/// Maps Firebase Auth error codes to [AuthFailureCode].
///
/// With email enumeration protection enabled Firebase reports wrong email
/// and wrong password alike as `invalid-credential`; the older codes are kept
/// for projects without it.
AuthFailureCode mapAuthErrorCode(String code) => switch (code) {
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' ||
  'INVALID_LOGIN_CREDENTIALS' => AuthFailureCode.invalidCredentials,
  'email-already-in-use' => AuthFailureCode.emailAlreadyInUse,
  'invalid-email' => AuthFailureCode.invalidEmail,
  'weak-password' => AuthFailureCode.weakPassword,
  'user-disabled' => AuthFailureCode.userDisabled,
  'too-many-requests' => AuthFailureCode.tooManyRequests,
  'network-request-failed' => AuthFailureCode.network,
  _ => AuthFailureCode.unknown,
};
