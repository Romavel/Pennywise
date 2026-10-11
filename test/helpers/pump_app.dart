import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/app/app.dart';
import 'package:pennywise/app/providers.dart';
import 'package:pennywise/core/config/app_config.dart';
import 'package:pennywise/features/auth/data/auth_providers.dart';
import 'package:pennywise/features/transactions/data/transaction_providers.dart';

import 'fake_auth_repository.dart';
import 'fake_transaction_repository.dart';

const testConfig = AppConfig(
  environment: AppEnvironment.dev,
  useFirebaseEmulators: false,
  emulatorHost: 'localhost',
);

/// Pumps the whole app with Firebase replaced by fakes.
///
/// [firebaseInit] succeeds immediately by default; [auth] defaults to a
/// repository with [testUser] signed in; [transactions] to an empty one.
Future<FakeAuthRepository> pumpPennywise(
  WidgetTester tester, {
  Future<void> Function()? firebaseInit,
  FakeAuthRepository? auth,
  FakeTransactionRepository? transactions,
}) async {
  final authRepository = auth ?? FakeAuthRepository(currentUser: testUser);
  // Phone-sized viewport, matching the 390×844 design frame.
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(testConfig),
        firebaseInitProvider.overrideWith(
          (ref) => (firebaseInit ?? () async {})(),
        ),
        authRepositoryProvider.overrideWithValue(authRepository),
        transactionRepositoryProvider.overrideWithValue(
          transactions ?? FakeTransactionRepository(),
        ),
      ],
      child: const PennywiseApp(),
    ),
  );
  return authRepository;
}
