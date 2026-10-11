import 'package:flutter/foundation.dart';

enum AppEnvironment { dev, prod }

/// Build-time configuration, passed with `--dart-define`:
///
/// * `APP_ENV` — `dev` (default) or `prod`.
/// * `USE_FIREBASE_EMULATORS` — `true` to talk to the local Firebase Emulator
///   Suite instead of the real project. Only allowed in `dev`.
/// * `FIREBASE_EMULATOR_HOST` — overrides the emulator host. Defaults to
///   `10.0.2.2` on Android (the host machine seen from the emulator) and
///   `localhost` elsewhere.
@immutable
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.useFirebaseEmulators,
    required this.emulatorHost,
  });

  factory AppConfig.fromEnvironment() {
    const envName = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
    const hostOverride = String.fromEnvironment('FIREBASE_EMULATOR_HOST');

    final environment = AppEnvironment.values.firstWhere(
      (e) => e.name == envName,
      orElse: () => throw ArgumentError.value(envName, 'APP_ENV'),
    );
    if (environment == AppEnvironment.prod && useEmulators) {
      throw StateError('Firebase emulators cannot be used in a prod build.');
    }

    return AppConfig(
      environment: environment,
      useFirebaseEmulators: useEmulators,
      emulatorHost: hostOverride.isNotEmpty
          ? hostOverride
          : defaultTargetPlatform == TargetPlatform.android
          ? '10.0.2.2'
          : 'localhost',
    );
  }

  final AppEnvironment environment;
  final bool useFirebaseEmulators;
  final String emulatorHost;

  bool get isProd => environment == AppEnvironment.prod;
}
