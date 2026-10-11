import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/core/utils/month.dart';
import 'package:pennywise/features/dashboard/domain/dashboard_summary.dart';
import 'package:pennywise/features/dashboard/domain/spending_breakdown.dart';
import 'package:pennywise/features/transactions/domain/transaction.dart';

Transaction tx(
  String id,
  String category,
  int amount, {
  TransactionType type = TransactionType.expense,
  DateTime? at,
}) => Transaction(
  id: id,
  type: type,
  amountMinor: amount,
  currency: 'PLN',
  categoryId: category,
  occurredAt: at ?? DateTime(2026, 10, 10),
);

void main() {
  group('SpendingBreakdown', () {
    test('ignores income and folds categories without a slot into Other', () {
      final breakdown = SpendingBreakdown.of([
        tx('1', 'housing', 150000),
        tx('2', 'food', 80000),
        tx('3', 'entertainment', 10000),
        tx('4', 'health', 5000),
        tx('5', 'other', 5000),
        tx('6', 'salary', 900000, type: TransactionType.income),
      ]);

      expect(breakdown.totalMinor, 250000);
      expect(breakdown.slices.map((s) => s.slot), [
        SpendingSlot.housing,
        SpendingSlot.food,
        SpendingSlot.other,
      ]);
      expect(breakdown.slices.last.amountMinor, 20000);
      expect(breakdown.slices.map((s) => s.percent), [60, 32, 8]);
    });

    test('keeps Other last even when it is the largest', () {
      final breakdown = SpendingBreakdown.of([
        tx('1', 'education', 90000),
        tx('2', 'food', 1000),
        tx('3', 'transport', 2000),
      ]);
      expect(breakdown.slices.map((s) => s.slot), [
        SpendingSlot.transport,
        SpendingSlot.food,
        SpendingSlot.other,
      ]);
    });

    test('tiny slices show as 1%, not 0%', () {
      final breakdown = SpendingBreakdown.of([
        tx('1', 'housing', 1000000),
        tx('2', 'food', 1),
      ]);
      expect(breakdown.slices.last.percent, 1);
    });

    test('is empty without expenses', () {
      expect(SpendingBreakdown.of([]).isEmpty, isTrue);
      expect(
        SpendingBreakdown.of([
          tx('1', 'salary', 100, type: TransactionType.income),
        ]).slices,
        isEmpty,
      );
    });
  });

  group('DashboardSummary', () {
    final all = [
      tx(
        'a',
        'salary',
        720000,
        type: TransactionType.income,
        at: DateTime(2026, 10, 1),
      ),
      tx('b', 'food', 8640, at: DateTime(2026, 10, 11, 9)),
      tx('c', 'transport', 3200, at: DateTime(2026, 10, 11, 8)),
      tx('d', 'housing', 250000, at: DateTime(2026, 9, 5)),
      tx(
        'e',
        'freelance',
        100000,
        type: TransactionType.income,
        at: DateTime(2026, 9, 20),
      ),
      tx('f', 'shopping', 18990, at: DateTime(2026, 10, 7)),
    ];

    test('balance covers all time, totals only the month', () {
      final summary = DashboardSummary.of(all, const Month(2026, 10));

      expect(summary.balanceMinor, 820000 - (8640 + 3200 + 250000 + 18990));
      expect(summary.monthTotals.incomeMinor, 720000);
      expect(summary.monthTotals.expenseMinor, 8640 + 3200 + 18990);
      expect(summary.spending.totalMinor, 8640 + 3200 + 18990);
      expect(summary.hasAnyTransactions, isTrue);
    });

    test('recent lists the newest transactions of the month', () {
      final summary = DashboardSummary.of(all, const Month(2026, 10));
      expect(summary.recent.map((t) => t.id), ['b', 'c', 'f', 'a']);

      final september = DashboardSummary.of(all, const Month(2026, 9));
      expect(september.recent.map((t) => t.id), ['e', 'd']);
    });

    test('handles a user without transactions', () {
      final summary = DashboardSummary.of([], const Month(2026, 10));
      expect(summary.balanceMinor, 0);
      expect(summary.recent, isEmpty);
      expect(summary.hasAnyTransactions, isFalse);
    });
  });
}
