import '../../../core/errors/app_failure.dart';

/// Account-level operations that go beyond signing in and out.
abstract interface class AccountRepository {
  /// Changes the name stored with the sign-in account.
  Future<void> updateDisplayName(String name);

  /// Confirms the user's identity with [password], then permanently deletes
  /// all of their data and the account itself on the server. The user is
  /// signed out afterwards.
  ///
  /// Throws [AuthFailure] for a wrong password and [AccountDeletionFailure]
  /// when the server cannot complete the deletion.
  Future<void> deleteAccount({required String password});
}

final class AccountDeletionFailure extends AppFailure {
  const AccountDeletionFailure({this.unavailable = false});

  /// The server function could not be reached (offline or not deployed).
  final bool unavailable;

  @override
  String get message => unavailable
      ? 'Account deletion isn’t available right now. Check your connection '
            'and try again.'
      : 'We couldn’t delete your account. Nothing was removed — please try '
            'again.';
}
