import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/core/errors/app_failure.dart';
import 'package:pennywise/features/transactions/domain/transaction.dart';
import 'package:pennywise/features/transactions/domain/transaction_repository.dart';

import '../../helpers/fake_transaction_repository.dart';
import '../../helpers/pump_app.dart';

final _existing = Transaction(
  id: 't1',
  type: TransactionType.expense,
  amountMinor: 8640,
  currency: 'PLN',
  categoryId: 'food',
  note: 'Weekly groceries',
  occurredAt: DateTime.now(),
);

Finder get _amountField => find.byKey(const Key('amount-field'));

Future<FakeTransactionRepository> _openNewForm(WidgetTester tester) async {
  final repo = FakeTransactionRepository();
  await pumpPennywise(tester, transactions: repo);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Add transaction'));
  await tester.pumpAndSettle();
  return repo;
}

Future<FakeTransactionRepository> _openExisting(WidgetTester tester) async {
  final repo = FakeTransactionRepository([_existing]);
  await pumpPennywise(tester, transactions: repo);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Transactions').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Weekly groceries'));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _tapPrimary(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows validation errors and saves nothing', (tester) async {
    final repo = await _openNewForm(tester);

    await _tapPrimary(tester, 'Add transaction');

    expect(find.text('Enter an amount greater than 0.'), findsOneWidget);
    expect(find.text('Choose a category.'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('adds an expense and returns to the previous screen', (
    tester,
  ) async {
    final repo = await _openNewForm(tester);

    await tester.enterText(_amountField, '45,99');
    await tester.tap(find.text('Food'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Add a note (optional)'),
      ' Groceries ',
    );
    await _tapPrimary(tester, 'Add transaction');

    expect(repo.calls, ['create']);
    final saved = repo.items.single;
    expect(saved.amountMinor, 4599);
    expect(saved.type, TransactionType.expense);
    expect(saved.categoryId, 'food');
    expect(saved.note, 'Groceries');
    expect(find.text('Transaction added'), findsOneWidget);
    expect(find.text('New transaction'), findsNothing);
  });

  testWidgets('the amount field rejects invalid characters', (tester) async {
    await _openNewForm(tester);

    await tester.enterText(_amountField, '12.345');
    expect(find.text('12.345'), findsNothing);
    await tester.enterText(_amountField, '12,3');
    expect(find.text('12,3'), findsOneWidget);
  });

  testWidgets('switching to income shows income categories', (tester) async {
    final repo = await _openNewForm(tester);

    await tester.tap(find.text('Food'));
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Food'), findsNothing);

    // The expense category was cleared, so one must be picked again.
    await tester.enterText(_amountField, '8200');
    await _tapPrimary(tester, 'Add transaction');
    expect(find.text('Choose a category.'), findsOneWidget);

    await tester.tap(find.text('Salary'));
    await _tapPrimary(tester, 'Add transaction');
    expect(repo.items.single.type, TransactionType.income);
    expect(repo.items.single.categoryId, 'salary');
  });

  testWidgets('reports offline saves', (tester) async {
    final repo = await _openNewForm(tester);
    repo.writeResult = WriteResult.pendingSync;

    await tester.enterText(_amountField, '10');
    await tester.tap(find.text('Transport'));
    await _tapPrimary(tester, 'Add transaction');

    expect(
      find.text(
        'Transaction added offline. It will sync when you’re back online.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps the form open and shows an error when saving fails', (
    tester,
  ) async {
    final repo = await _openNewForm(tester);
    repo.nextWriteError = const DataFailure(DataFailureCode.permissionDenied);

    await tester.enterText(_amountField, '10');
    await tester.tap(find.text('Transport'));
    await _tapPrimary(tester, 'Add transaction');

    expect(find.text('New transaction'), findsOneWidget);
    expect(
      find.text('You don’t have access to this data. Try logging in again.'),
      findsOneWidget,
    );
  });

  testWidgets('edits an existing transaction', (tester) async {
    final repo = await _openExisting(tester);

    expect(find.text('Edit transaction'), findsOneWidget);
    await tester.enterText(_amountField, '90.10');
    await _tapPrimary(tester, 'Save changes');

    expect(repo.calls, ['update']);
    expect(repo.items.single.amountMinor, 9010);
    expect(repo.items.single.note, 'Weekly groceries');
    expect(find.text('Changes saved'), findsOneWidget);
    expect(find.text('−90.10'), findsOneWidget);
  });

  testWidgets('deleting asks for confirmation', (tester) async {
    final repo = await _openExisting(tester);

    await tester.tap(find.byTooltip('Delete transaction'));
    await tester.pumpAndSettle();
    expect(find.text('Delete transaction?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);

    await tester.tap(find.byTooltip('Delete transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repo.calls, ['delete']);
    expect(repo.items, isEmpty);
    expect(find.text('Transaction deleted'), findsOneWidget);
    expect(find.text('Edit transaction'), findsNothing);
  });
}
