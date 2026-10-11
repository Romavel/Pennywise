import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_providers.dart';

/// Submission state of the log in / sign up form. Navigation after success
/// is driven by the router reacting to [authStateProvider].
final authControllerProvider =
    NotifierProvider.autoDispose<AuthController, AsyncValue<void>>(
      AuthController.new,
    );

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn({required String email, required String password}) =>
      _run(
        () => ref
            .read(authRepositoryProvider)
            .signIn(email: email, password: password),
      );

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) => _run(
    () => ref
        .read(authRepositoryProvider)
        .signUp(email: email, password: password, displayName: displayName),
  );

  /// Clears a previous error, e.g. when switching between log in and sign up.
  void reset() {
    if (!state.isLoading) state = const AsyncData(null);
  }

  Future<void> _run(Future<void> Function() action) async {
    // Ignore repeated taps while a request is in flight.
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) state = result;
  }
}

/// Submission state of the "forgot password" sheet.
final passwordResetControllerProvider =
    NotifierProvider.autoDispose<PasswordResetController, AsyncValue<bool>>(
      PasswordResetController.new,
    );

/// `true` once the reset email has been requested.
class PasswordResetController extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() => const AsyncData(false);

  Future<void> send(String email) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      return true;
    });
    if (ref.mounted) state = result;
  }
}
