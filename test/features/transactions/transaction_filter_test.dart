import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/core/utils/month.dart';
import 'package:pennywise/features/transactions/domain/transaction.dart';
import 'package:pennywise/features/transactions/domain/transaction_filter.dart';
import 'package:pennywise/features/transactions/domain/transaction_validators.dart';

Transaction tx(
  String id, {
  TransactionType type = TransactionType.expense,
  int amount = 1000,
  String category = 'food',
  String note = '',
  required DateTime at,
}) => Transaction(
  id: id,
  type: type,
  amountMinor: amount,
  currency: 'PLN',
  categoryId: category,
  note: note,
  occurredAt: at,
);

void main() {
  const october = Month(2026, 10);
  final transactions = [
    tx(
      'a',
      note: 'Weekly groceries',
      amount: 8640,
      at: DateTime(2026, 10, 11, 9),
    ),
    tx(
      'b',
      category: 'transport',
      note: 'Ride to the office',
      amount: 3200,
      at: DateTime(2026, 10, 11, 8),
    ),
    tx(
      'c',
      type: TransactionType.income,
      category: 'freelance',
      note: 'Landing page',
      amount: 100000,
      at: DateTime(2026, 10, 9),
    ),
    tx('d', note: 'Groceries', amount: 2000, at: DateTime(2026, 10, 7)),
    tx('e', note: 'September rent', amount: 150000, at: DateTime(2026, 9, 30)),
  ];

  List<String> ids(TransactionFilter f) =>
      f.apply(transactions).map((t) => t.id).toList();

  group('TransactionFilter.apply', () {
    test('keeps only the month, newest first', () {
      expect(ids(const TransactionFilter(month: october)), [
        'a',
        'b',
        'c',
        'd',
      ]);
    });

    test('can sort oldest first', () {
      expect(
        ids(
          const TransactionFilter(
            month: october,
            sort: TransactionSort.oldestFirst,
          ),
        ),
        ['d', 'c', 'b', 'a'],
      );
    });

    test('filters by type and category', () {
      expect(
        ids(
          const TransactionFilter(month: october, type: TransactionType.income),
        ),
        ['c'],
      );
      expect(ids(const TransactionFilter(month: october, categoryId: 'food')), [
        'a',
        'd',
      ]);
    });

    test('searches notes case-insensitively', () {
      expect(ids(const TransactionFilter(month: october, query: '  GROCER ')), [
        'a',
        'd',
      ]);
      expect(
        ids(const TransactionFilter(month: october, query: 'nothing')),
        isEmpty,
      );
    });
  });

  test('TransactionTotals sums income and expenses separately', () {
    final totals = TransactionTotals.of(
      const TransactionFilter(month: october).apply(transactions),
    );
    expect(totals.incomeMinor, 100000);
    expect(totals.expenseMinor, 8640 + 3200 + 2000);
    expect(totals.balanceMinor, 100000 - 13840);
  });

  test('groupByDay keeps list order', () {
    final groups = groupByDay(
      const TransactionFilter(month: october).apply(transactions),
    );
    expect(groups.map((g) => g.day.day), [11, 9, 7]);
    expect(groups.first.transactions.map((t) => t.id), ['a', 'b']);
  });

  group('TransactionValidators', () {
    test('amount must be a positive number', () {
      expect(
        TransactionValidators.amount(''),
        'Enter an amount greater than 0.',
      );
      expect(
        TransactionValidators.amount('0.00'),
        'Enter an amount greater than 0.',
      );
      expect(TransactionValidators.amount('12.345'), isNotNull);
      expect(TransactionValidators.amount('45,99'), isNull);
    });

    test('category is required, note is limited', () {
      expect(TransactionValidators.category(null), 'Choose a category.');
      expect(TransactionValidators.category('food'), isNull);
      expect(TransactionValidators.note('x' * 200), isNull);
      expect(TransactionValidators.note('x' * 201), isNotNull);
    });
  });
}
