import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/core/errors/app_failure.dart';
import 'package:pennywise/core/utils/month.dart';
import 'package:pennywise/features/dashboard/presentation/spending_chart.dart';
import 'package:pennywise/features/transactions/domain/transaction.dart';

import '../../helpers/fake_transaction_repository.dart';
import '../../helpers/pump_app.dart';

final _now = DateTime.now();
final _thisMonth = Month.current();
final _firstOfMonth = DateTime(_now.year, _now.month, 1, 9);
final _lastMonth = DateTime(_now.year, _now.month - 1, 15);

Transaction _tx(
  String id,
  String category,
  int amount, {
  TransactionType type = TransactionType.expense,
  String note = '',
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
  _tx(
    'a',
    'salary',
    720000,
    type: TransactionType.income,
    note: 'Salary',
    at: _firstOfMonth,
  ),
  _tx('b', 'housing', 150000, note: 'Rent', at: _firstOfMonth),
  _tx('c', 'food', 8640, note: 'Weekly groceries'),
  _tx(
    'd',
    'freelance',
    100000,
    type: TransactionType.income,
    note: 'Old project',
    at: _lastMonth,
  ),
];

Future<FakeTransactionRepository> _pumpDashboard(
  WidgetTester tester, [
  List<Transaction> items = const [],
]) async {
  final repo = FakeTransactionRepository(items);
  await pumpPennywise(tester, transactions: repo);
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('greets the user and shows the balance and month totals', (
    tester,
  ) async {
    await _pumpDashboard(tester, _sample);

    expect(find.text('Jan'), findsOneWidget);
    expect(find.text(_thisMonth.label), findsOneWidget);
    // All time: 7,200 + 1,000 - 1,500 - 86.40.
    expect(find.text('PLN 6,613.60'), findsOneWidget);
    // In the income tile and on the salary row.
    expect(find.text('+7,200.00'), findsNWidgets(2));
    expect(find.text('−1,586.40'), findsOneWidget);
  });

  testWidgets('shows spending by category and recent transactions', (
    tester,
  ) async {
    await _pumpDashboard(tester, _sample);

    expect(find.byType(SpendingChart), findsOneWidget);
    expect(find.text('Housing'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget);
    expect(find.text('5%'), findsOneWidget);
    expect(find.text('1,586'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Weekly groceries'), 200);
    expect(find.text('Food & Groceries · Today'), findsOneWidget);
    expect(find.text('Old project'), findsNothing);
  });

  testWidgets('tapping a legend row shows that category in the middle', (
    tester,
  ) async {
    await _pumpDashboard(tester, _sample);

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    expect(find.text('86'), findsOneWidget);
  });

  testWidgets('changing the month updates the totals', (tester) async {
    await _pumpDashboard(tester, _sample);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();

    expect(find.text(_thisMonth.previous.label), findsOneWidget);
    expect(find.text('+1,000.00'), findsNWidgets(2));
    expect(find.text('0.00'), findsOneWidget);
    expect(
      find.text('No expenses in ${_thisMonth.previous.monthName} yet.'),
      findsOneWidget,
    );
    // The balance stays all-time.
    expect(find.text('PLN 6,613.60'), findsOneWidget);
  });

  testWidgets('a new transaction updates the dashboard', (tester) async {
    await _pumpDashboard(tester);
    expect(find.text('PLN 0.00'), findsOneWidget);
    expect(
      find.text('No transactions yet. Tap + to add your first one.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amount-field')), '50');
    await tester.tap(find.text('Food'));
    final save = find.widgetWithText(FilledButton, 'Add transaction');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('−PLN 50.00'), findsOneWidget);
    expect(find.text('−50.00'), findsWidgets);
    expect(find.byType(SpendingChart), findsOneWidget);
  });

  testWidgets('"See all" opens the transactions of the same month', (
    tester,
  ) async {
    await _pumpDashboard(tester, _sample);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    final seeAll = find.text('See all');
    await tester.ensureVisible(seeAll);
    await tester.tap(seeAll);
    await tester.pumpAndSettle();

    expect(find.text('Old project'), findsOneWidget);
    expect(find.text(_thisMonth.previous.label), findsOneWidget);
  });

  testWidgets('shows an error state when loading fails', (tester) async {
    final repo = FakeTransactionRepository()
      ..watchError = const DataFailure(DataFailureCode.unavailable);
    await pumpPennywise(tester, transactions: repo);
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t load your data'), findsOneWidget);
    expect(
      find.text('Good morning,').evaluate().isNotEmpty ||
          find.text('Good afternoon,').evaluate().isNotEmpty ||
          find.text('Good evening,').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
