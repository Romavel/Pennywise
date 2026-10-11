import 'package:flutter/foundation.dart';

import '../../../core/utils/dates.dart';
import '../../../core/utils/month.dart';
import 'transaction.dart';

enum TransactionSort { newestFirst, oldestFirst }

/// What the transaction list shows. The month is queried from Firestore;
/// type, category and search are applied on the device, which keeps the
/// queries simple (no composite indexes) for one month of data.
@immutable
class TransactionFilter {
  const TransactionFilter({
    required this.month,
    this.type,
    this.categoryId,
    this.query = '',
    this.sort = TransactionSort.newestFirst,
  });

  final Month month;
  final TransactionType? type;
  final String? categoryId;
  final String query;
  final TransactionSort sort;

  bool get hasNarrowing =>
      type != null || categoryId != null || query.trim().isNotEmpty;

  TransactionFilter copyWith({
    Month? month,
    TransactionType? Function()? type,
    String? Function()? categoryId,
    String? query,
    TransactionSort? sort,
  }) => TransactionFilter(
    month: month ?? this.month,
    type: type != null ? type() : this.type,
    categoryId: categoryId != null ? categoryId() : this.categoryId,
    query: query ?? this.query,
    sort: sort ?? this.sort,
  );

  /// Applies type, category, note search and sort order.
  List<Transaction> apply(Iterable<Transaction> transactions) {
    final needle = query.trim().toLowerCase();
    final result = transactions.where((t) {
      if (!month.contains(t.occurredAt)) return false;
      if (type != null && t.type != type) return false;
      if (categoryId != null && t.categoryId != categoryId) return false;
      if (needle.isNotEmpty && !t.note.toLowerCase().contains(needle)) {
        return false;
      }
      return true;
    }).toList();

    result.sort((a, b) {
      final byDate = a.occurredAt.compareTo(b.occurredAt);
      // Stable order for equal dates.
      final cmp = byDate != 0 ? byDate : a.id.compareTo(b.id);
      return sort == TransactionSort.newestFirst ? -cmp : cmp;
    });
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.month == month &&
      other.type == type &&
      other.categoryId == categoryId &&
      other.query == query &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(month, type, categoryId, query, sort);
}

/// Income and expense totals, both positive.
@immutable
class TransactionTotals {
  const TransactionTotals({
    required this.incomeMinor,
    required this.expenseMinor,
  });

  factory TransactionTotals.of(Iterable<Transaction> transactions) {
    var income = 0;
    var expense = 0;
    for (final t in transactions) {
      if (t.isIncome) {
        income += t.amountMinor;
      } else {
        expense += t.amountMinor;
      }
    }
    return TransactionTotals(incomeMinor: income, expenseMinor: expense);
  }

  final int incomeMinor;
  final int expenseMinor;

  int get balanceMinor => incomeMinor - expenseMinor;
}

/// Transactions of one day, in list order.
typedef DayGroup = ({DateTime day, List<Transaction> transactions});

/// Groups an already sorted list by calendar day, keeping its order.
List<DayGroup> groupByDay(List<Transaction> sorted) {
  final groups = <DayGroup>[];
  for (final t in sorted) {
    final day = Dates.dayOf(t.occurredAt);
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.transactions.add(t);
    } else {
      groups.add((day: day, transactions: [t]));
    }
  }
  return groups;
}
