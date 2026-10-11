import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/core/utils/month.dart';
import 'package:pennywise/features/budgets/domain/budget.dart';
import 'package:pennywise/features/budgets/domain/budget_progress.dart';
import 'package:pennywise/features/budgets/domain/category_history.dart';
import 'package:pennywise/features/transactions/domain/transaction.dart';

const october = Month(2026, 10);

Budget budget(String category, int limit, {Month month = october}) => Budget(
  categoryId: category,
  month: month,
  limitMinor: limit,
  currency: 'PLN',
);

Transaction tx(
  String category,
  int amount, {
  TransactionType type = TransactionType.expense,
  DateTime? at,
}) => Transaction(
  id: '$category-$amount-${at?.month}',
  type: type,
  amountMinor: amount,
  currency: 'PLN',
  categoryId: category,
  occurredAt: at ?? DateTime(2026, 10, 10),
);

void main() {
  group('Budget id', () {
    test('is derived from month and category and can be parsed back', () {
      expect(budget('food', 1).id, '2026-10_food');
      expect(Budget.parseId('2026-10_other_income'), (
        month: october,
        categoryId: 'other_income',
      ));
      expect(Budget.parseId('nonsense'), isNull);
      expect(Budget.parseId('2026-13_food'), isNull);
    });
  });

  group('BudgetProgress', () {
    test('sums only expenses of the category in the budget month', () {
      final progress = BudgetProgress.of(budget('food', 120000), [
        tx('food', 50000),
        tx('food', 34260),
        tx('food', 99999, at: DateTime(2026, 9, 30)),
        tx('transport', 10000),
        // Income in the same category id never counts.
        tx('food', 70000, type: TransactionType.income),
      ]);

      expect(progress.spentMinor, 84260);
      expect(progress.remainingMinor, 35740);
      expect(progress.percent, 70);
      expect(progress.status, BudgetStatus.ok);
    });

    test('is "near" from 90% and "over" above the limit', () {
      BudgetStatus statusFor(int spent) => BudgetProgress(
        budget: budget('food', 10000),
        spentMinor: spent,
      ).status;

      expect(statusFor(8999), BudgetStatus.ok);
      expect(statusFor(9000), BudgetStatus.near);
      expect(statusFor(10000), BudgetStatus.near);
      expect(statusFor(10001), BudgetStatus.over);
    });

    test('reports how much is over the limit', () {
      final progress = BudgetProgress(
        budget: budget('transport', 30000),
        spentMinor: 31000,
      );
      expect(progress.overMinor, 1000);
      expect(progress.remainingMinor, -1000);
      expect(progress.percent, 103);
    });
  });

  group('BudgetOverview', () {
    test('totals all budgets, sorts by limit and lists the ones over', () {
      final overview = BudgetOverview.of(
        [
          budget('transport', 30000),
          budget('housing', 170000),
          budget('food', 120000),
        ],
        [tx('housing', 165000), tx('food', 84260), tx('transport', 31000)],
      );

      expect(overview.items.map((p) => p.budget.categoryId), [
        'housing',
        'food',
        'transport',
      ]);
      expect(overview.limitMinor, 320000);
      expect(overview.spentMinor, 280260);
      expect(overview.remainingMinor, 39740);
      expect(overview.overLimit.single.budget.categoryId, 'transport');
    });
  });

  group('category history', () {
    test('monthsEndingAt counts back across years', () {
      expect(monthsEndingAt(const Month(2026, 2), 4), [
        const Month(2025, 11),
        const Month(2025, 12),
        const Month(2026, 1),
        const Month(2026, 2),
      ]);
    });

    test('sums the category per month, including empty months', () {
      final history = categorySpendingByMonth(
        [
          tx('transport', 24000, at: DateTime(2026, 8, 3)),
          tx('transport', 31000, at: DateTime(2026, 10, 3)),
          tx('transport', 500, at: DateTime(2026, 10, 9)),
          tx('food', 9999, at: DateTime(2026, 10, 3)),
        ],
        categoryId: 'transport',
        months: monthsEndingAt(october, 3),
      );
      expect(history.map((h) => h.spentMinor), [24000, 0, 31500]);
    });
  });
}
