import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/core/utils/month.dart';
import 'package:pennywise/features/budgets/domain/budget.dart';
import 'package:pennywise/features/transactions/domain/transaction.dart';

import '../../helpers/fake_budget_repository.dart';
import '../../helpers/fake_transaction_repository.dart';
import '../../helpers/pump_app.dart';

final _month = Month.current();
final _now = DateTime.now();

Budget _budget(String category, int limit, {Month? month}) => Budget(
  categoryId: category,
  month: month ?? _month,
  limitMinor: limit,
  currency: 'PLN',
);

Transaction _expense(
  String id,
  String category,
  int amount, {
  String note = '',
}) => Transaction(
  id: id,
  type: TransactionType.expense,
  amountMinor: amount,
  currency: 'PLN',
  categoryId: category,
  note: note,
  occurredAt: _now,
);

final _transactions = [
  _expense('t1', 'housing', 165000, note: 'Rent'),
  _expense('t2', 'food', 84260, note: 'Groceries'),
  _expense('t3', 'transport', 31000, note: 'Fuel'),
];

Future<({FakeBudgetRepository budgets, FakeTransactionRepository transactions})>
_openBudgets(
  WidgetTester tester, {
  List<Budget> budgets = const [],
  List<Transaction>? transactions,
}) async {
  final budgetRepo = FakeBudgetRepository(budgets);
  final txRepo = FakeTransactionRepository(transactions ?? _transactions);
  await pumpPennywise(tester, budgets: budgetRepo, transactions: txRepo);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Budgets').last);
  await tester.pumpAndSettle();
  return (budgets: budgetRepo, transactions: txRepo);
}

void main() {
  testWidgets('lists budgets with totals and warns about overspending', (
    tester,
  ) async {
    await _openBudgets(
      tester,
      budgets: [
        _budget('housing', 170000),
        _budget('food', 120000),
        _budget('transport', 30000),
      ],
    );

    expect(find.text('Left to spend this month'), findsOneWidget);
    // 3,200.00 - (1,650.00 + 842.60 + 310.00)
    expect(find.text('PLN 397.40'), findsOneWidget);
    expect(find.text('Spent 2,802.60 of 3,200.00'), findsOneWidget);
    expect(
      find.text('Transport is over its limit by PLN 10.00'),
      findsOneWidget,
    );
    expect(find.text('PLN 842.60 of 1,200.00'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.text('97%'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('PLN 10.00 over limit'), 200);
    expect(find.text('103%'), findsOneWidget);
  });

  testWidgets('creates a budget for a category', (tester) async {
    final repos = await _openBudgets(tester);

    expect(find.text('No budgets for ${_month.monthName}'), findsOneWidget);
    await tester.tap(find.text('New budget'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create budget'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a category.'), findsOneWidget);
    expect(find.text('Enter a limit greater than 0.'), findsOneWidget);

    await tester.tap(find.text('Food & Groceries'));
    await tester.enterText(find.byKey(const Key('budget-limit-field')), '1200');
    await tester.tap(find.text('Create budget'));
    await tester.pumpAndSettle();

    expect(repos.budgets.calls, ['create']);
    expect(repos.budgets.items.single.id, Budget.idFor(_month, 'food'));
    expect(repos.budgets.items.single.limitMinor, 120000);
    expect(find.text('Budget created'), findsOneWidget);
    expect(find.text('PLN 842.60 of 1,200.00'), findsOneWidget);
  });

  testWidgets('only offers categories without a budget', (tester) async {
    await _openBudgets(tester, budgets: [_budget('food', 1000)]);

    await tester.tap(find.text('New budget'));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Housing')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Food & Groceries')),
      findsNothing,
    );
  });

  testWidgets('copies last month\'s budgets into an empty month', (
    tester,
  ) async {
    final repos = await _openBudgets(
      tester,
      budgets: [
        _budget('food', 120000, month: _month.previous),
        _budget('housing', 170000, month: _month.previous),
      ],
    );

    await tester.tap(find.text('Copy 2 from ${_month.previous.monthName}'));
    await tester.pumpAndSettle();

    expect(repos.budgets.calls, ['copyTo']);
    expect(find.text('Budgets copied'), findsOneWidget);
    expect(find.text('PLN 1,650.00 of 1,700.00'), findsOneWidget);
  });

  testWidgets('opens the budget details', (tester) async {
    await _openBudgets(tester, budgets: [_budget('transport', 30000)]);

    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();

    expect(find.text('Spent this month'), findsOneWidget);
    expect(find.text('PLN 10.00 over your limit'), findsOneWidget);
    expect(find.text('Last 6 months'), findsOneWidget);
    expect(
      find.text('Over the current limit in 1 of the last 6 months.'),
      findsOneWidget,
    );
    expect(find.text('−10.00'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Fuel'), 200);
    expect(find.text('Fuel'), findsOneWidget);
  });

  testWidgets('edits the limit and deletes a budget from the details', (
    tester,
  ) async {
    final repos = await _openBudgets(
      tester,
      budgets: [_budget('transport', 30000)],
    );
    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit budget limit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('budget-limit-field')), '400');
    await tester.tap(find.text('Save limit'));
    await tester.pumpAndSettle();

    expect(repos.budgets.items.single.limitMinor, 40000);
    expect(find.text('PLN 90.00 left to spend'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit budget limit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repos.budgets.items, isEmpty);
    expect(find.text('Budget deleted'), findsOneWidget);
    expect(find.text('No budgets for ${_month.monthName}'), findsOneWidget);
  });

  testWidgets('the dashboard summarises the month\'s budgets', (tester) async {
    await pumpPennywise(
      tester,
      budgets: FakeBudgetRepository([
        _budget('food', 120000),
        _budget('transport', 30000),
      ]),
      transactions: FakeTransactionRepository(_transactions),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('1 over limit'), 200);
    expect(find.text('77% used · PLN 347.40 left'), findsOneWidget);
  });
}
