// End-to-end flows on a device or emulator, against the Firebase Emulator
// Suite (Auth + Firestore, with the real security rules). Run with:
//
//   firebase emulators:exec --only auth,firestore --project pennywise-5fa13 \
//     "flutter test integration_test --dart-define=USE_FIREBASE_EMULATORS=true"
//
// CI runs this on an Android emulator (.github/workflows/integration.yml).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pennywise/app/app.dart';
import 'package:pennywise/app/providers.dart';
import 'package:pennywise/core/config/app_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final config = AppConfig.fromEnvironment();
  // Never run these flows against a real Firebase project.
  if (!config.useFirebaseEmulators) {
    throw StateError(
      'Integration tests need --dart-define=USE_FIREBASE_EMULATORS=true',
    );
  }

  // A fresh account per run, so reruns don't collide.
  final email = 'flow${DateTime.now().millisecondsSinceEpoch}@example.com';
  const password = 'password123';

  testWidgets('sign up, record transactions, budgets follow, sign in again', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(config)],
        child: const PennywiseApp(),
      ),
    );

    // --- Sign up --------------------------------------------------------
    await tester.waitFor(find.text('Welcome back'));
    await tester.tap(find.text('Sign up'));
    await tester.settle();
    await tester.enterText(tester.field('auth-name'), 'Integration');
    await tester.enterText(tester.field('auth-email'), email);
    await tester.enterText(tester.field('auth-password'), password);
    await tester.tapVisible(
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.waitFor(find.text('Total balance'));
    expect(find.text('PLN 0.00'), findsOneWidget);

    // --- Create a budget ------------------------------------------------
    await tester.openTab('Budgets');
    await tester.tap(find.text('New budget'));
    await tester.settle();
    await tester.tap(find.text('Food & Groceries'));
    await tester.enterText(find.byKey(const Key('budget-limit-field')), '200');
    await tester.tap(find.text('Create budget'));
    await tester.waitFor(find.text('PLN 0.00 of 200.00'));

    // --- Add a transaction; the budget follows ----------------------------
    await tester.openTab('Transactions');
    await tester.tap(find.byTooltip('Add transaction'));
    await tester.settle();
    await tester.enterText(find.byKey(const Key('amount-field')), '45.99');
    await tester.tap(find.text('Food'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Add a note (optional)'),
      'Groceries',
    );
    await tester.tapVisible(
      find.widgetWithText(FilledButton, 'Add transaction'),
    );
    await tester.waitFor(find.text('Groceries'));
    await tester.openTab('Budgets');
    await tester.waitFor(find.text('PLN 45.99 of 200.00'));

    // --- Edit it over the limit --------------------------------------------
    await tester.openTab('Transactions');
    await tester.tap(find.text('Groceries'));
    await tester.waitFor(find.text('Edit transaction'));
    await tester.enterText(find.byKey(const Key('amount-field')), '250');
    await tester.tapVisible(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.waitFor(find.text('−250.00'));
    await tester.openTab('Budgets');
    await tester.waitFor(
      find.text('Food & Groceries is over its limit by PLN 50.00'),
    );

    // --- Delete it ------------------------------------------------------
    await tester.openTab('Transactions');
    await tester.tap(find.text('Groceries'));
    await tester.waitFor(find.byTooltip('Delete transaction'));
    await tester.tap(find.byTooltip('Delete transaction'));
    await tester.settle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.waitFor(find.textContaining('No transactions in'));
    await tester.openTab('Budgets');
    await tester.waitFor(find.text('PLN 0.00 of 200.00'));

    // --- Log out ----------------------------------------------------------
    await tester.openTab('Settings');
    await tester.tapVisible(find.text('Log out'));
    await tester.waitFor(find.text('Welcome back'));

    // --- Firebase errors are shown in plain words ---------------------------
    await tester.tap(find.text('Sign up'));
    await tester.settle();
    await tester.enterText(tester.field('auth-name'), 'Someone else');
    await tester.enterText(tester.field('auth-email'), email);
    await tester.enterText(tester.field('auth-password'), password);
    await tester.tapVisible(
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.waitFor(
      find.text(
        'An account with this email already exists. Try logging in instead.',
      ),
    );

    await tester.tap(find.text('Log in'));
    await tester.settle();
    await tester.enterText(tester.field('auth-email'), email);
    await tester.enterText(tester.field('auth-password'), 'wrong-password');
    await tester.tapVisible(find.widgetWithText(FilledButton, 'Log in'));
    await tester.waitFor(
      find.text(
        'That email and password don’t match. Check them and try again.',
      ),
    );

    // --- Log in again: the data is still there --------------------------------
    await tester.enterText(tester.field('auth-password'), password);
    await tester.tapVisible(find.widgetWithText(FilledButton, 'Log in'));
    await tester.waitFor(find.text('Total balance'));
    await tester.openTab('Budgets');
    await tester.waitFor(find.text('PLN 0.00 of 200.00'));
  });
}

extension on WidgetTester {
  /// Pumps frames until [finder] matches, while real time passes for network
  /// calls to the emulators.
  Future<void> waitFor(
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw TestFailure('Timed out after $timeout waiting for $finder');
  }

  /// Lets animations finish without waiting on spinners forever.
  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await pump(const Duration(milliseconds: 100));
    }
  }

  Finder field(String key) => find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextFormField),
  );

  Future<void> tapVisible(Finder finder) async {
    await ensureVisible(finder);
    await settle();
    await tap(finder);
    await settle();
  }

  Future<void> openTab(String label) async {
    await tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await settle();
  }
}
