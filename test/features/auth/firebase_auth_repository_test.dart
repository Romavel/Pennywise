import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pennywise/features/auth/data/firebase_auth_repository.dart';
import 'package:pennywise/features/auth/domain/app_user.dart';
import 'package:pennywise/features/auth/domain/auth_failure.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockUserCredential extends Mock implements UserCredential {}

void main() {
  late _MockFirebaseAuth auth;
  late FirebaseAuthRepository repository;

  setUp(() {
    auth = _MockFirebaseAuth();
    repository = FirebaseAuthRepository(auth);
  });

  test('maps Firebase users to AppUser', () async {
    final user = _MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => user.email).thenReturn('jan@example.com');
    when(() => user.displayName).thenReturn('Jan');
    when(() => auth.userChanges()).thenAnswer((_) => Stream.value(user));

    expect(
      await repository.authStateChanges().first,
      const AppUser(uid: 'u1', email: 'jan@example.com', displayName: 'Jan'),
    );
  });

  test('signIn trims the email', () async {
    when(
      () => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _MockUserCredential());

    await repository.signIn(email: ' jan@example.com ', password: 'secret');

    verify(
      () => auth.signInWithEmailAndPassword(
        email: 'jan@example.com',
        password: 'secret',
      ),
    ).called(1);
  });

  test('signUp creates the account and sets the display name', () async {
    final user = _MockUser();
    final credential = _MockUserCredential();
    when(() => credential.user).thenReturn(user);
    when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
    when(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => credential);

    await repository.signUp(
      email: 'jan@example.com',
      password: 'password123',
      displayName: ' Jan ',
    );

    verify(() => user.updateDisplayName('Jan')).called(1);
  });

  test('Firebase errors become AuthFailure', () async {
    when(
      () => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

    expect(
      () => repository.signIn(email: 'a@b.co', password: 'x'),
      throwsA(
        isA<AuthFailure>().having(
          (f) => f.code,
          'code',
          AuthFailureCode.invalidCredentials,
        ),
      ),
    );
  });

  test('mapAuthErrorCode covers the documented codes', () {
    expect(
      mapAuthErrorCode('wrong-password'),
      AuthFailureCode.invalidCredentials,
    );
    expect(
      mapAuthErrorCode('user-not-found'),
      AuthFailureCode.invalidCredentials,
    );
    expect(
      mapAuthErrorCode('email-already-in-use'),
      AuthFailureCode.emailAlreadyInUse,
    );
    expect(mapAuthErrorCode('invalid-email'), AuthFailureCode.invalidEmail);
    expect(mapAuthErrorCode('weak-password'), AuthFailureCode.weakPassword);
    expect(mapAuthErrorCode('user-disabled'), AuthFailureCode.userDisabled);
    expect(
      mapAuthErrorCode('too-many-requests'),
      AuthFailureCode.tooManyRequests,
    );
    expect(mapAuthErrorCode('network-request-failed'), AuthFailureCode.network);
    expect(mapAuthErrorCode('something-new'), AuthFailureCode.unknown);
  });
}
