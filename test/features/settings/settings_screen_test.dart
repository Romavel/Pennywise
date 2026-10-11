import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/app/theme/app_colors.dart';
import 'package:pennywise/features/auth/presentation/auth_screen.dart';
import 'package:pennywise/features/settings/domain/user_profile.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_settings_repositories.dart';
import '../../helpers/pump_app.dart';

Future<
  ({
    FakeProfileRepository profile,
    FakeAccountRepository account,
    FakeAuthRepository auth,
  })
>
_openSettings(WidgetTester tester, {UserProfile? stored}) async {
  final auth = FakeAuthRepository(currentUser: testUser);
  final profile = FakeProfileRepository(stored);
  final account = FakeAccountRepository(auth);
  await pumpPennywise(tester, auth: auth, profile: profile, account: account);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Settings').last);
  await tester.pumpAndSettle();
  return (profile: profile, account: account, auth: auth);
}

void main() {
  testWidgets('shows the profile with defaults before anything is saved', (
    tester,
  ) async {
    await _openSettings(tester);

    expect(find.text('Jan'), findsNWidgets(2));
    expect(find.text('jan@example.com'), findsOneWidget);
    expect(find.text('PLN · Polish złoty'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(
      find.text('Changing currency doesn’t convert past amounts.'),
      findsOneWidget,
    );
  });

  testWidgets('saves the theme to the profile', (tester) async {
    final repos = await _openSettings(tester);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(repos.profile.profile?.themeMode, ThemeMode.dark);
    final context = tester.element(find.byType(NavigationBar));
    expect(context.pwColors, PennywiseColors.dark);
  });

  testWidgets('uses the stored theme and name after a restart', (tester) async {
    await _openSettings(
      tester,
      stored: const UserProfile(
        displayName: 'Janek',
        currency: 'EUR',
        themeMode: ThemeMode.dark,
      ),
    );

    expect(find.text('Janek'), findsNWidgets(2));
    expect(find.text('EUR · Euro'), findsOneWidget);
    final context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('changes the display name everywhere', (tester) async {
    final repos = await _openSettings(tester);

    await tester.tap(find.text('Display name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('display-name-field')), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your name.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('display-name-field')),
      'Jakub',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repos.profile.profile?.displayName, 'Jakub');
    expect(repos.account.displayName, 'Jakub');
    expect(find.text('Jakub'), findsNWidgets(2));

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Jakub'), findsOneWidget);
  });

  testWidgets('changes the base currency for new transactions', (tester) async {
    final repos = await _openSettings(tester);

    await tester.tap(find.text('Base currency'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Euro'));
    await tester.pumpAndSettle();

    expect(repos.profile.profile?.currency, 'EUR');
    expect(find.text('EUR · Euro'), findsOneWidget);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('EUR 0.00'), findsOneWidget);
    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();
    expect(find.text('EUR'), findsOneWidget);
  });

  testWidgets('deleting the account needs the right password', (tester) async {
    final repos = await _openSettings(tester);

    await tester.scrollUntilVisible(find.text('Delete account'), 200);
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete account?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your password to confirm.'), findsOneWidget);
    expect(repos.account.calls, isEmpty);

    await tester.enterText(
      find.byKey(const Key('delete-password-field')),
      'wrong',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Delete account'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'That email and password don’t match. Check them and try again.',
      ),
      findsOneWidget,
    );
    expect(repos.auth.currentUser, isNotNull);

    await tester.enterText(
      find.byKey(const Key('delete-password-field')),
      'password123',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Delete account'));
    await tester.pumpAndSettle();

    expect(repos.auth.currentUser, isNull);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Your account and data were deleted.'), findsOneWidget);
  });

  testWidgets('keeps the user signed in when the server step fails', (
    tester,
  ) async {
    final repos = await _openSettings(tester);
    repos.account.failDeletion = true;

    await tester.scrollUntilVisible(find.text('Delete account'), 200);
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('delete-password-field')),
      'password123',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Delete account'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('We couldn’t delete your account.'),
      findsOneWidget,
    );
    expect(repos.auth.currentUser, isNotNull);
  });
}
