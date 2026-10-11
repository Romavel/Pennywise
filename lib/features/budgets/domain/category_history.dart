import '../../../core/utils/month.dart';
import '../../transactions/domain/transaction.dart';

/// The [count] months ending with [last], oldest first.
List<Month> monthsEndingAt(Month last, int count) {
  final months = <Month>[last];
  while (months.length < count) {
    months.insert(0, months.first.previous);
  }
  return months;
}

/// Expenses of [categoryId] per month, oldest first.
List<({Month month, int spentMinor})> categorySpendingByMonth(
  Iterable<Transaction> transactions, {
  required String categoryId,
  required List<Month> months,
}) {
  final totals = {for (final m in months) m: 0};
  for (final t in transactions) {
    if (t.isIncome || t.categoryId != categoryId) continue;
    final month = Month.of(t.occurredAt);
    if (totals.containsKey(month)) {
      totals[month] = totals[month]! + t.amountMinor;
    }
  }
  return [for (final m in months) (month: m, spentMinor: totals[m]!)];
}
