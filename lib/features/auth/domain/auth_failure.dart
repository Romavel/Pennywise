import '../../../core/errors/app_failure.dart';

enum AuthFailureCode {
  invalidCredentials,
  emailAlreadyInUse,
  invalidEmail,
  weakPassword,
  userDisabled,
  tooManyRequests,
  network,
  unknown,
}

final class AuthFailure extends AppFailure {
  const AuthFailure(this.code);

  final AuthFailureCode code;

  @override
  String get message => switch (code) {
    AuthFailureCode.invalidCredentials =>
      'That email and password don’t match. Check them and try again.',
    AuthFailureCode.emailAlreadyInUse =>
      'An account with this email already exists. Try logging in instead.',
    AuthFailureCode.invalidEmail => 'Enter a valid email address.',
    AuthFailureCode.weakPassword =>
      'This password is too weak. Use at least 8 characters.',
    AuthFailureCode.userDisabled =>
      'This account has been disabled. Contact support for help.',
    AuthFailureCode.tooManyRequests =>
      'Too many attempts. Wait a moment and try again.',
    AuthFailureCode.network =>
      'No connection. Check your internet and try again.',
    AuthFailureCode.unknown => 'Something went wrong. Please try again.',
  };
}
