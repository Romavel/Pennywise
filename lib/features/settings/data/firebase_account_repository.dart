import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/data/firebase_auth_repository.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/account_repository.dart';

/// Region of the `deleteAccount` Cloud Function (see `functions/`).
const functionsRegion = 'europe-central2';

class FirebaseAccountRepository implements AccountRepository {
  FirebaseAccountRepository(this._auth, this._functions);

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure(AuthFailureCode.unknown);
    return user;
  }

  @override
  Future<void> updateDisplayName(String name) async {
    try {
      await _user.updateDisplayName(name.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(mapAuthErrorCode(e.code));
    }
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    final user = _user;
    try {
      // Deleting needs a fresh sign-in; the server also checks its age.
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(mapAuthErrorCode(e.code));
    }

    try {
      await _functions.httpsCallable('deleteAccount').call<void>();
    } on FirebaseFunctionsException catch (e) {
      throw AccountDeletionFailure(
        unavailable: e.code == 'unavailable' || e.code == 'not-found',
      );
    }

    // The account no longer exists on the server; clear the local session.
    await _auth.signOut();
  }
}
