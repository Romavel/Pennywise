import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/features/auth/domain/auth_validators.dart';

void main() {
  group('email', () {
    test('accepts valid addresses, ignoring surrounding spaces', () {
      expect(AuthValidators.email('jan@example.com'), isNull);
      expect(AuthValidators.email('  jan.kowalski+pw@mail.co.uk '), isNull);
    });

    test('rejects empty and malformed addresses', () {
      for (final value in [null, '', '   ']) {
        expect(AuthValidators.email(value), 'Enter your email.');
      }
      for (final value in [
        'jan',
        'jan@',
        '@example.com',
        'jan@example',
        'j an@example.com',
        'jan@@example.com',
      ]) {
        expect(
          AuthValidators.email(value),
          'Enter a valid email address.',
          reason: value,
        );
      }
    });
  });

  group('passwords', () {
    test('new password needs at least 8 characters', () {
      expect(AuthValidators.newPassword(''), 'Enter a password.');
      expect(AuthValidators.newPassword('1234567'), isNotNull);
      expect(AuthValidators.newPassword('12345678'), isNull);
    });

    test('login password only needs to be present', () {
      expect(AuthValidators.loginPassword(''), 'Enter your password.');
      expect(AuthValidators.loginPassword('short'), isNull);
    });
  });

  group('display name', () {
    test('is required and limited in length', () {
      expect(AuthValidators.displayName('  '), 'Enter your name.');
      expect(AuthValidators.displayName('Jan'), isNull);
      expect(AuthValidators.displayName('a' * 40), isNull);
      expect(AuthValidators.displayName('a' * 41), isNotNull);
    });
  });
}
