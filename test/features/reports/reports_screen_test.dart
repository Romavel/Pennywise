import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/core/utils/month.dart';
import 'package:pennywise/features/budgets/domain/budget.dart';
import 'package:pennywise/features/transactions/domain/transaction.dart';

import '../../helpers/fake_budget_repository.dart';
import '../../helpers/fake_transaction_repository.dart';
import '../../helpers/pump_app.dart';

final _month = Month.current();

Transaction _tx(
  String id,
  String category,
  int amount,
  Month month, {
  TransactionType type = TransactionType.expense,
}) => Transaction(
  id: id,
  type: type,
  amountMinor: amount,
  currency: 'PLN',
  categoryId: category,
  occurredAt: month.start.add(const Duration(hours: 12)),
);

Future<void> _openReports(
  WidgetTester tester, {
  List<Transaction> transactions = const [],
  List<Budget> budgets = const [],
}) async {
  await pumpPennywise(
    tester,
    transactions: FakeTransactionRepository(transactions),
    budgets: FakeBudgetRepository(budgets),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Reports').last);
  await tester.pumpAndSettle();
}

void main() {
  final sample = [
    _tx('1', 'salary', 720000, _month, type: TransactionType.income),
    _tx('2', 'housing', 165000, _month),
    _tx('3', 'food', 75000, _month),
    _tx('4', 'housing', 165000, _month.previous),
    _tx('5', 'food', 135000, _month.previous),
  ];

  testWidgets('shows key figures, charts and top categories', (tester) async {
    await _openReports(tester, transactions: sample);

    expect(find.text('Avg. monthly spend'), findsOneWidget);
    // (2,400 + 3,000) / 6 months.
    expect(find.text('PLN 900'), findsOneWidget);
    expect(
      find.text('Spending vs ${_month.previous.monthName}'),
      findsOneWidget,
    );
    expect(find.text('20%'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    expect(find.text('Income vs expenses'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Top spending categories'), 200);
    expect(find.text('Housing'), findsOneWidget);
    expect(find.text('Food & Groceries'), findsOneWidget);
  });

  testWidgets('switching the period updates the figures', (tester) async {
    await _openReports(tester, transactions: sample);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('Spent this month'), findsOneWidget);
    expect(find.text('PLN 2,400'), findsOneWidget);

    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    expect(find.text('PLN 450'), findsOneWidget);
  });

  testWidgets('summarises budget history', (tester) async {
    await _openReports(
      tester,
      transactions: sample,
      budgets: [
        Budget(
          categoryId: 'food',
          month: _month,
          limitMinor: 100000,
          currency: 'PLN',
        ),
        Budget(
          categoryId: 'food',
          month: _month.previous,
          limitMinor: 100000,
          currency: 'PLN',
        ),
      ],
    );

    await tester.scrollUntilVisible(find.text('Budget history'), 200);
    expect(find.text('Within budget 1 of 2 months'), findsOneWidget);
  });

  testWidgets('shows an empty state without transactions', (tester) async {
    await _openReports(tester);
    expect(find.text('Nothing to report yet'), findsOneWidget);
  });
}
