import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/core/utils/month.dart';
import 'package:pennywise/features/budgets/domain/budget.dart';
import 'package:pennywise/features/reports/domain/report.dart';
import 'package:pennywise/features/transactions/domain/transaction.dart';

const october = Month(2026, 10);

Transaction tx(
  String category,
  int amount,
  DateTime at, {
  TransactionType type = TransactionType.expense,
}) => Transaction(
  id: '$category-$amount-$at',
  type: type,
  amountMinor: amount,
  currency: 'PLN',
  categoryId: category,
  occurredAt: at,
);

void main() {
  final transactions = [
    tx('salary', 720000, DateTime(2026, 10, 1), type: TransactionType.income),
    tx('housing', 165000, DateTime(2026, 10, 2)),
    tx('food', 84000, DateTime(2026, 10, 5)),
    tx('transport', 31000, DateTime(2026, 10, 6)),
    tx('salary', 720000, DateTime(2026, 9, 1), type: TransactionType.income),
    tx('housing', 165000, DateTime(2026, 9, 2)),
    tx('food', 120000, DateTime(2026, 9, 5)),
    // Outside a six-month window ending in October.
    tx('food', 999999, DateTime(2026, 3, 5)),
  ];
  const budgets = [
    Budget(
      categoryId: 'transport',
      month: october,
      limitMinor: 30000,
      currency: 'PLN',
    ),
    Budget(
      categoryId: 'food',
      month: Month(2026, 9),
      limitMinor: 150000,
      currency: 'PLN',
    ),
  ];

  Report report(ReportPeriod period) => Report.of(
    transactions: transactions,
    budgets: budgets,
    period: period,
    current: october,
  );

  test('covers the months of the period, oldest first', () {
    final r = report(ReportPeriod.sixMonths);
    expect(r.months.map((m) => m.month.month), [5, 6, 7, 8, 9, 10]);
    expect(r.months.last.totals.incomeMinor, 720000);
    expect(r.months.last.totals.expenseMinor, 280000);
    expect(report(ReportPeriod.year).months, hasLength(12));
    expect(report(ReportPeriod.month).months.single.month, october);
  });

  test('averages spending over the period', () {
    expect(
      report(ReportPeriod.sixMonths).averageMonthlySpendMinor,
      (280000 + 285000) ~/ 6,
    );
    expect(report(ReportPeriod.month).averageMonthlySpendMinor, 280000);
  });

  test('compares this month with the previous one', () {
    // 280,000 vs 285,000: about 1.75% less.
    expect(report(ReportPeriod.month).spendingChange, closeTo(-0.0175, 0.0001));

    final noHistory = Report.of(
      transactions: [tx('food', 100, DateTime(2026, 10, 1))],
      budgets: const [],
      period: ReportPeriod.month,
      current: october,
    );
    expect(noHistory.spendingChange, isNull);
  });

  test('ranks top categories within the period', () {
    final top = report(ReportPeriod.sixMonths).topCategories;
    expect(top.map((c) => c.categoryId), ['housing', 'food', 'transport']);
    expect(top.first.amountMinor, 330000);
    expect(top.first.percent, 58);
  });

  test('records the budget outcome of each month', () {
    final r = report(ReportPeriod.sixMonths);
    expect(r.budgetHistory.map((h) => h.outcome), [
      BudgetMonthOutcome.none,
      BudgetMonthOutcome.none,
      BudgetMonthOutcome.none,
      BudgetMonthOutcome.none,
      BudgetMonthOutcome.within,
      BudgetMonthOutcome.over,
    ]);
    expect(r.monthsWithBudgets, 2);
    expect(r.monthsWithinBudget, 1);
  });

  test('knows when there is nothing to report', () {
    final empty = Report.of(
      transactions: const [],
      budgets: const [],
      period: ReportPeriod.sixMonths,
      current: october,
    );
    expect(empty.hasTransactions, isFalse);
    expect(empty.topCategories, isEmpty);
  });
}
