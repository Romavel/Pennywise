import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/features/auth/domain/auth_failure.dart';
import 'package:pennywise/features/auth/presentation/auth_screen.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/pump_app.dart';

Finder _field(String key) => find.descendant(
  of: find.byKey(Key(key)),
  matching: find.byType(TextFormField),
);

Future<FakeAuthRepository> _pumpSignedOut(WidgetTester tester) async {
  final auth = await pumpPennywise(tester, auth: FakeAuthRepository());
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  testWidgets('signed-out users land on the log in screen', (tester) async {
    await _pumpSignedOut(tester);

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('shows validation errors without calling Firebase', (
    tester,
  ) async {
    final auth = await _pumpSignedOut(tester);

    await tester.enterText(_field('auth-email'), 'not-an-email');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('logs in and opens the dashboard', (tester) async {
    final auth = await _pumpSignedOut(tester);

    await tester.enterText(_field('auth-email'), 'jan@example.com');
    await tester.enterText(_field('auth-password'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(auth.calls, ['signIn']);
    expect(find.byType(AuthScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('shows a readable message when login fails', (tester) async {
    final auth = await _pumpSignedOut(tester);
    auth.nextError = const AuthFailure(AuthFailureCode.invalidCredentials);

    await tester.enterText(_field('auth-email'), 'jan@example.com');
    await tester.enterText(_field('auth-password'), 'wrong');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'That email and password don’t match. Check them and try again.',
      ),
      findsOneWidget,
    );
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('blocks repeated submits while a request is running', (
    tester,
  ) async {
    final auth = await _pumpSignedOut(tester);
    auth.pending = Completer<void>();

    await tester.enterText(_field('auth-email'), 'jan@example.com');
    await tester.enterText(_field('auth-password'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(auth.calls, ['signIn']);

    auth.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('signs up with a display name', (tester) async {
    final auth = await _pumpSignedOut(tester);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('At least 8 characters.'), findsOneWidget);

    await tester.enterText(_field('auth-email'), 'jan@example.com');
    await tester.enterText(_field('auth-password'), 'short');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your name.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(auth.calls, isEmpty);

    await tester.enterText(_field('auth-name'), 'Jan');
    await tester.enterText(_field('auth-password'), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(auth.calls, ['signUp']);
    expect(auth.currentUser?.displayName, 'Jan');
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('sends a password reset link', (tester) async {
    final auth = await _pumpSignedOut(tester);

    await tester.enterText(_field('auth-email'), 'jan@example.com');
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(auth.calls, ['sendPasswordResetEmail']);
    expect(
      find.textContaining('If an account exists for jan@example.com'),
      findsOneWidget,
    );

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Reset password'), findsNothing);
  });

  testWidgets('logging out returns to the log in screen', (tester) async {
    final auth = await pumpPennywise(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('jan@example.com'), findsOneWidget);

    await tester.ensureVisible(find.text('Log out'));
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(auth.calls, ['signOut']);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
