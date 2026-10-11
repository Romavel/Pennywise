import 'package:flutter/foundation.dart';

import '../../../core/utils/month.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_filter.dart';
import 'spending_breakdown.dart';

/// Everything the dashboard shows for one month.
@immutable
class DashboardSummary {
  const DashboardSummary({
    required this.month,
    required this.balanceMinor,
    required this.monthTotals,
    required this.spending,
    required this.recent,
    required this.hasAnyTransactions,
  });

  /// Builds the summary from all of the user's transactions.
  factory DashboardSummary.of(
    List<Transaction> all,
    Month month, {
    int recentCount = 4,
  }) {
    final inMonth = TransactionFilter(month: month).apply(all);
    return DashboardSummary(
      month: month,
      balanceMinor: TransactionTotals.of(all).balanceMinor,
      monthTotals: TransactionTotals.of(inMonth),
      spending: SpendingBreakdown.of(inMonth),
      recent: inMonth.take(recentCount).toList(),
      hasAnyTransactions: all.isNotEmpty,
    );
  }

  final Month month;

  /// Income minus expenses across all recorded transactions (not a bank
  /// balance).
  final int balanceMinor;
  final TransactionTotals monthTotals;
  final SpendingBreakdown spending;

  /// Latest transactions of [month], newest first.
  final List<Transaction> recent;
  final bool hasAnyTransactions;
}
