import 'package:flutter/material.dart';

/// Preferences stored in `users/{uid}`, synced across the user's devices.
@immutable
class UserProfile {
  const UserProfile({
    required this.displayName,
    this.currency = defaultCurrency,
    this.themeMode = ThemeMode.system,
  });

  static const defaultCurrency = 'PLN';
  static const maxNameLength = 40;

  final String displayName;

  /// ISO 4217 code used for new transactions and budgets. Changing it does
  /// not convert amounts that were already recorded.
  final String currency;
  final ThemeMode themeMode;

  UserProfile copyWith({
    String? displayName,
    String? currency,
    ThemeMode? themeMode,
  }) => UserProfile(
    displayName: displayName ?? this.displayName,
    currency: currency ?? this.currency,
    themeMode: themeMode ?? this.themeMode,
  );

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.displayName == displayName &&
      other.currency == currency &&
      other.themeMode == themeMode;

  @override
  int get hashCode => Object.hash(displayName, currency, themeMode);
}

/// Currencies offered as the base currency.
abstract final class Currencies {
  static const supported = <String, String>{
    'PLN': 'Polish złoty',
    'EUR': 'Euro',
    'USD': 'US dollar',
    'GBP': 'British pound',
    'CHF': 'Swiss franc',
    'CZK': 'Czech koruna',
    'SEK': 'Swedish krona',
    'NOK': 'Norwegian krone',
    'DKK': 'Danish krone',
    'UAH': 'Ukrainian hryvnia',
  };

  static String label(String code) =>
      supported[code] == null ? code : '$code · ${supported[code]}';
}
