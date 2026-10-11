import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/core/errors/app_failure.dart';
import 'package:pennywise/core/utils/month.dart';
import 'package:pennywise/features/transactions/domain/transaction.dart';

import '../../helpers/fake_transaction_repository.dart';
import '../../helpers/pump_app.dart';

final _now = DateTime.now();
final _earlierThisMonth = DateTime(_now.year, _now.month, 1, 9);

Transaction _tx(
  String id,
  String note, {
  TransactionType type = TransactionType.expense,
  String category = 'food',
  int amount = 1000,
  DateTime? at,
}) => Transaction(
  id: id,
  type: type,
  amountMinor: amount,
  currency: 'PLN',
  categoryId: category,
  note: note,
  occurredAt: at ?? _now,
);

final _sample = [
  _tx('a', 'Weekly groceries', amount: 8640),
  _tx(
    'b',
    'Landing page project',
    type: TransactionType.income,
    category: 'freelance',
    amount: 100000,
    at: _earlierThisMonth,
  ),
  _tx(
    'c',
    'Autumn jacket',
    category: 'shopping',
    amount: 18990,
    at: _earlierThisMonth,
  ),
];

Future<FakeTransactionRepository> _openTransactions(
  WidgetTester tester, [
  List<Transaction> items = const [],
]) async {
  final repo = FakeTransactionRepository(items);
  await pumpPennywise(tester, transactions: repo);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Transactions').last);
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('lists the month with totals', (tester) async {
    await _openTransactions(tester, _sample);

    expect(find.text(Month.current().label), findsOneWidget);
    expect(find.textContaining('+1,000.00'), findsWidgets);
    expect(find.textContaining('−276.30'), findsOneWidget); // 86.40 + 189.90
    expect(find.text('Weekly groceries'), findsOneWidget);
    expect(find.text('Food & Groceries'), findsOneWidget);
    expect(find.text('−86.40'), findsOneWidget);
  });

  testWidgets('filters by type', (tester) async {
    await _openTransactions(tester, _sample);

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('Landing page project'), findsOneWidget);
    expect(find.text('Weekly groceries'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('Weekly groceries'), findsOneWidget);
  });

  testWidgets('filters by category', (tester) async {
    await _openTransactions(tester, _sample);

    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Shopping'));
    await tester.pumpAndSettle();

    expect(find.text('Autumn jacket'), findsOneWidget);
    expect(find.text('Weekly groceries'), findsNothing);
  });

  testWidgets('search narrows the list and can be cleared', (tester) async {
    await _openTransactions(tester, _sample);

    await tester.enterText(find.byType(TextField), 'jacket');
    await tester.pumpAndSettle();
    expect(find.text('Autumn jacket'), findsOneWidget);
    expect(find.text('Weekly groceries'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nothing like this');
    await tester.pumpAndSettle();
    expect(find.text('No matching transactions'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Weekly groceries'), findsOneWidget);
  });

  testWidgets('shows an empty state for a month without data', (tester) async {
    await _openTransactions(tester, _sample);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text(Month.current().previous.label), findsOneWidget);
    expect(
      find.text('No transactions in ${Month.current().previous.monthName}'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Add transaction'));
    await tester.pumpAndSettle();
    expect(find.text('New transaction'), findsOneWidget);
  });

  testWidgets('shows an error state when loading fails', (tester) async {
    final repo = FakeTransactionRepository()
      ..watchError = const DataFailure(DataFailureCode.unavailable);
    await pumpPennywise(tester, transactions: repo);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transactions').last);
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t load your data'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('tapping a transaction opens it for editing', (tester) async {
    await _openTransactions(tester, _sample);

    await tester.tap(find.text('Weekly groceries'));
    await tester.pumpAndSettle();

    expect(find.text('Edit transaction'), findsOneWidget);
    expect(find.text('86.40'), findsOneWidget);
    expect(find.byTooltip('Delete transaction'), findsOneWidget);
  });
}
