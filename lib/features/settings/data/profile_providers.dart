import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../domain/account_repository.dart';
import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';
import 'firebase_account_repository.dart';
import 'firestore_profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final uid = ref.watch(authStateProvider.select((auth) => auth.value?.uid));
  if (uid == null) {
    throw StateError('The profile is only available when signed in.');
  }
  return FirestoreProfileRepository(FirebaseFirestore.instance, uid: uid);
});

final _storedProfileProvider = StreamProvider<UserProfile?>(
  (ref) => ref.watch(profileRepositoryProvider).watch(),
);

/// The signed-in user's profile, with defaults until one is saved: the
/// name from sign-up, PLN and the system theme. `null` when signed out.
final profileProvider = Provider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  final stored = ref.watch(_storedProfileProvider).value;
  final fallbackName = user.displayName?.trim().isNotEmpty ?? false
      ? user.displayName!.trim()
      : user.email.split('@').first;
  if (stored == null) return UserProfile(displayName: fallbackName);
  return stored.displayName.isEmpty
      ? stored.copyWith(displayName: fallbackName)
      : stored;
});

/// Theme from the profile; the system theme when signed out.
final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(profileProvider)?.themeMode ?? ThemeMode.system,
);

/// Base currency for new transactions and budgets.
final currencyProvider = Provider<String>(
  (ref) => ref.watch(profileProvider)?.currency ?? UserProfile.defaultCurrency,
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => FirebaseAccountRepository(
    FirebaseAuth.instance,
    FirebaseFunctions.instanceFor(region: functionsRegion),
  ),
);
