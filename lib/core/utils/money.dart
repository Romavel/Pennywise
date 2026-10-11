import 'package:intl/intl.dart';

/// Amounts are stored as integers in the currency's minor unit (grosze for
/// PLN) to avoid floating point errors. This file converts between that
/// representation and text.
abstract final class Money {
  /// Largest amount accepted in a single transaction, in major units.
  static const maxMajorUnits = 1000000000;
  static const maxMinor = maxMajorUnits * 100;

  static final _format = NumberFormat('#,##0.00', 'en_US');

  // Digits, optionally followed by "." or "," and up to two decimals.
  static final _amountInput = RegExp(r'^(\d+)(?:[.,](\d{0,2}))?$');

  /// Parses user input such as `45`, `45.9`, `45,99` or `1 234,50` into
  /// minor units. Returns `null` for anything else, including more than two
  /// decimals or values above [maxMajorUnits].
  static int? parseMinor(String input) {
    final text = input.replaceAll(RegExp(r'[\s ]'), '');
    final match = _amountInput.firstMatch(text);
    if (match == null) return null;

    final whole = int.tryParse(match.group(1)!);
    if (whole == null || whole > maxMajorUnits) return null;
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    final minor = whole * 100 + int.parse(fraction);
    return minor > maxMinor ? null : minor;
  }

  /// `458299` → `4,582.99`.
  static String format(int minor) => _format.format(minor / 100);

  static final _wholeFormat = NumberFormat('#,##0', 'en_US');

  /// Whole major units, rounded down: `341240` → `3,412`.
  static String formatWhole(int minor) => _wholeFormat.format(minor ~/ 100);

  /// `+4,582.99` / `−4,582.99` (with a real minus sign); zero has no sign.
  static String formatSigned(int minor, {required bool positive}) {
    if (minor == 0) return format(0);
    return '${positive ? '+' : '−'}${format(minor.abs())}';
  }

  /// Text for an editable amount field: `4599` → `45.99`.
  static String toInput(int minor) =>
      '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';
}
