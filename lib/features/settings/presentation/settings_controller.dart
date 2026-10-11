import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_providers.dart';
import '../domain/user_profile.dart';

/// Saves profile changes.
final settingsControllerProvider =
    NotifierProvider.autoDispose<SettingsController, AsyncValue<void>>(
      SettingsController.new,
    );

class SettingsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  UserProfile get _profile => ref.read(profileProvider)!;

  /// Updates the profile and the sign-in account, so both stay in sync.
  Future<void> updateDisplayName(String name) => _run(() async {
    final trimmed = name.trim();
    await ref
        .read(profileRepositoryProvider)
        .save(_profile.copyWith(displayName: trimmed));
    await ref.read(accountRepositoryProvider).updateDisplayName(trimmed);
  });

  Future<void> updateCurrency(String currency) => _run(
    () => ref
        .read(profileRepositoryProvider)
        .save(_profile.copyWith(currency: currency)),
  );

  Future<void> updateTheme(ThemeMode mode) => _run(
    () => ref
        .read(profileRepositoryProvider)
        .save(_profile.copyWith(themeMode: mode)),
  );

  Future<void> _run(Future<void> Function() action) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) state = result;
  }
}

/// Deletes the account. Separate from [settingsControllerProvider] because
/// its errors are shown in the confirmation dialog, not as a snackbar.
final deleteAccountControllerProvider =
    NotifierProvider.autoDispose<DeleteAccountController, AsyncValue<void>>(
      DeleteAccountController.new,
    );

class DeleteAccountController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> delete(String password) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () =>
          ref.read(accountRepositoryProvider).deleteAccount(password: password),
    );
    if (ref.mounted) state = result;
  }
}
