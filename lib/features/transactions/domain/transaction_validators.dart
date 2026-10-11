import '../../../core/utils/money.dart';

/// Validation for the transaction form. Firestore Security Rules enforce the
/// same limits on the server.
abstract final class TransactionValidators {
  static const maxNoteLength = 200;

  static String? amount(String? input) {
    final text = input?.trim() ?? '';
    if (text.isEmpty) return 'Enter an amount greater than 0.';
    final minor = Money.parseMinor(text);
    if (minor == null) return 'Enter a valid amount, e.g. 45.99.';
    if (minor <= 0) return 'Enter an amount greater than 0.';
    return null;
  }

  static String? category(String? categoryId) =>
      categoryId == null || categoryId.isEmpty ? 'Choose a category.' : null;

  static String? note(String? note) =>
      (note ?? '').trim().length > maxNoteLength
      ? 'Keep the note under $maxNoteLength characters.'
      : null;
}
