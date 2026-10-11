import 'package:flutter/foundation.dart';

import '../../../core/utils/month.dart';
import '../../budgets/domain/budget.dart';
import '../../budgets/domain/budget_progress.dart';
import '../../budgets/domain/category_history.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_filter.dart';

enum ReportPeriod {
  month(1, 'Month'),
  sixMonths(6, '6 months'),
  year(12, 'Year');

  const ReportPeriod(this.months, this.label);

  final int months;
  final String label;
}

@immutable
class MonthTotals {
  const MonthTotals(this.month, this.totals);

  final Month month;
  final TransactionTotals totals;
}

@immutable
class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.amountMinor,
    required this.share,
  });

  final String categoryId;
  final int amountMinor;

  /// Fraction of all spending in the period, 0–1.
  final double share;

  int get percent => (share * 100).round();
}

enum BudgetMonthOutcome {
  /// No budgets were set that month.
  none,

  /// Every budget stayed within its limit.
  within,

  /// At least one budget went over its limit.
  over,
}

/// Statistics for a period ending with the current month, computed from the
/// saved transactions and budgets.
@immutable
class Report {
  const Report({
    required this.period,
    required this.months,
    required this.topCategories,
    required this.budgetHistory,
    required this.spendingChange,
  });

  factory Report.of({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required ReportPeriod period,
    required Month current,
    int topCount = 5,
  }) {
    final months = monthsEndingAt(current, period.months);
    final first = months.first;
    final inPeriod = transactions
        .where(
          (t) =>
              !t.occurredAt.isBefore(first.start) &&
              t.occurredAt.isBefore(current.end),
        )
        .toList();

    final perMonth = [
      for (final m in months)
        MonthTotals(
          m,
          TransactionTotals.of(inPeriod.where((t) => m.contains(t.occurredAt))),
        ),
    ];

    // Top categories by spending in the period.
    final byCategory = <String, int>{};
    for (final t in inPeriod) {
      if (t.isIncome) continue;
      byCategory[t.categoryId] =
          (byCategory[t.categoryId] ?? 0) + t.amountMinor;
    }
    final totalSpent = byCategory.values.fold(0, (sum, v) => sum + v);
    final top = [
      for (final MapEntry(key: id, value: amount) in byCategory.entries)
        CategoryTotal(
          categoryId: id,
          amountMinor: amount,
          share: amount / totalSpent,
        ),
    ]..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));

    // Budget outcome per month.
    final budgetsByMonth = <Month, List<Budget>>{};
    for (final b in budgets) {
      budgetsByMonth.putIfAbsent(b.month, () => []).add(b);
    }
    final history = [
      for (final m in months)
        (
          month: m,
          outcome: switch (budgetsByMonth[m]) {
            null || [] => BudgetMonthOutcome.none,
            final monthBudgets
                when BudgetOverview.of(
                  monthBudgets,
                  inPeriod,
                ).overLimit.isNotEmpty =>
              BudgetMonthOutcome.over,
            _ => BudgetMonthOutcome.within,
          },
        ),
    ];

    // Current month's spending compared with the previous month's.
    final previousSpent = TransactionTotals.of(
      transactions.where((t) => current.previous.contains(t.occurredAt)),
    ).expenseMinor;
    final currentSpent = perMonth.last.totals.expenseMinor;

    return Report(
      period: period,
      months: perMonth,
      topCategories: top.take(topCount).toList(),
      budgetHistory: history,
      spendingChange: previousSpent == 0
          ? null
          : (currentSpent - previousSpent) / previousSpent,
    );
  }

  final ReportPeriod period;

  /// Oldest first; the last entry is the current month.
  final List<MonthTotals> months;
  final List<CategoryTotal> topCategories;
  final List<({Month month, BudgetMonthOutcome outcome})> budgetHistory;

  /// Change of this month's spending vs the previous month (0.19 = +19%);
  /// `null` when there was no spending last month to compare with.
  final double? spendingChange;

  Month get current => months.last.month;

  int get totalSpentMinor =>
      months.fold(0, (sum, m) => sum + m.totals.expenseMinor);

  int get averageMonthlySpendMinor => totalSpentMinor ~/ months.length;

  bool get hasTransactions =>
      months.any((m) => m.totals.incomeMinor > 0 || m.totals.expenseMinor > 0);

  int get monthsWithBudgets =>
      budgetHistory.where((h) => h.outcome != BudgetMonthOutcome.none).length;

  int get monthsWithinBudget =>
      budgetHistory.where((h) => h.outcome == BudgetMonthOutcome.within).length;
}
