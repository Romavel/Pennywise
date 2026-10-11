/// Form validators for the auth screens. Each returns an error message or
/// `null` when the value is valid. Firebase validates again on the server.
abstract final class AuthValidators {
  static const minPasswordLength = 8;
  static const maxDisplayNameLength = 40;

  // Pragmatic check: one @, no spaces, a dot in the domain part.
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email.';
    if (!_email.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  /// For logging in: only checks presence, so existing accounts with older
  /// password rules can still sign in.
  static String? loginPassword(String? value) =>
      (value ?? '').isEmpty ? 'Enter your password.' : null;

  static String? newPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter a password.';
    if (password.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters.';
    }
    return null;
  }

  static String? displayName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter your name.';
    if (name.length > maxDisplayNameLength) {
      return 'Use at most $maxDisplayNameLength characters.';
    }
    return null;
  }
}
