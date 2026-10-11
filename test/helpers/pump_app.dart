import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/app/app.dart';
import 'package:pennywise/app/providers.dart';
import 'package:pennywise/core/config/app_config.dart';

const testConfig = AppConfig(
  environment: AppEnvironment.dev,
  useFirebaseEmulators: false,
  emulatorHost: 'localhost',
);

/// Pumps the whole app with Firebase initialization replaced by
/// [firebaseInit] (succeeds immediately by default).
Future<void> pumpPennywise(
  WidgetTester tester, {
  Future<void> Function()? firebaseInit,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(testConfig),
        firebaseInitProvider.overrideWith(
          (ref) => (firebaseInit ?? () async {})(),
        ),
      ],
      child: const PennywiseApp(),
    ),
  );
}
