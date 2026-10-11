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

  group('overall budget', () {
    test('counts every expense of the month, never income', () {
      final progress =
          BudgetProgress.of(budget(Budget.overallCategoryId, 300000), [
            tx('housing', 165000),
            tx('food', 84000),
            tx('entertainment', 4800),
            tx('salary', 720000, type: TransactionType.income),
            tx('food', 99999, at: DateTime(2026, 9, 30)),
          ]);
      expect(progress.spentMinor, 253800);
      expect(progress.budget.isOverall, isTrue);
    });

    test('drives the month totals and is kept apart from the categories', () {
      final overview = BudgetOverview.of(
        [
          budget(Budget.overallCategoryId, 250000),
          budget('food', 100000),
          budget('housing', 170000),
        ],
        [tx('housing', 165000), tx('food', 84000), tx('health', 9000)],
      );

      expect(overview.items.map((p) => p.budget.categoryId), [
        'housing',
        'food',
      ]);
      expect(overview.overall?.spentMinor, 258000);
      expect(overview.limitMinor, 250000);
      expect(overview.spentMinor, 258000);
      expect(overview.remainingMinor, -8000);
      expect(overview.categoryLimitsMinor, 270000);
      expect(overview.categoryLimitsExceedOverall, isTrue);
      expect(overview.overLimit.single.budget.isOverall, isTrue);
    });

    test('without it the totals are the sum of category budgets', () {
      final overview = BudgetOverview.of(
        [budget('food', 100000)],
        [tx('food', 50000), tx('health', 9000)],
      );
      expect(overview.overall, isNull);
      expect(overview.spentMinor, 50000);
      expect(overview.categoryLimitsExceedOverall, isFalse);
    });

    test('history with no category counts all expenses', () {
      final history = categorySpendingByMonth(
        [tx('food', 100), tx('transport', 200)],
        categoryId: null,
        months: [october],
      );
      expect(history.single.spentMinor, 300);
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
