import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import 'firebase_bootstrap.dart';

/// Overridden in `main.dart` with the value read from `--dart-define`.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden'),
);

/// Completes when Firebase is ready. The splash screen shows its state and
/// the router keeps the user on the splash screen until it succeeds.
///
/// Automatic retries are disabled: a missing configuration will not fix
/// itself, and network failures are retried explicitly by the user.
final firebaseInitProvider = FutureProvider<void>(
  (ref) => initializeFirebase(ref.watch(appConfigProvider)),
  retry: (retryCount, error) => null,
);
