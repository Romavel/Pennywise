import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/features/categories/domain/category_catalog.dart';
import 'package:pennywise/features/transactions/domain/transaction.dart';

import '../../helpers/fake_settings_repositories.dart';
import '../../helpers/fake_transaction_repository.dart';
import '../../helpers/pump_app.dart';

Future<FakeCategoryRepository> _openCategories(
  WidgetTester tester, {
  UserCategories initial = const UserCategories(),
  FakeTransactionRepository? transactions,
}) async {
  final repo = FakeCategoryRepository(initial);
  await pumpPennywise(tester, categories: repo, transactions: transactions);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Settings').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Categories'));
  await tester.pumpAndSettle();
  return repo;
}

const _coffee = CustomCategory(
  id: 'custom_coffee0001',
  name: 'Coffee',
  type: TransactionType.expense,
  iconKey: 'coffee',
  toneKey: 'brown',
);

void main() {
  testWidgets('lists built-in categories per type', (tester) async {
    await _openCategories(tester);

    expect(find.text('Food & Groceries'), findsOneWidget);
    expect(find.text('DEFAULT'), findsNWidgets(8));

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('DEFAULT'), findsNWidgets(4));
  });

  testWidgets('creates a custom category usable in the transaction form', (
    tester,
  ) async {
    final repo = await _openCategories(tester);

    await tester.tap(find.text('New category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create category'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('category-name-field')),
      'Coffee',
    );
    await tester.tap(find.bySemanticsLabel('Icon coffee'));
    await tester.tap(find.bySemanticsLabel('Colour brown'));
    await tester.tap(find.text('Create category'));
    await tester.pumpAndSettle();

    final created = repo.current.custom.single;
    expect(created.name, 'Coffee');
    expect(created.iconKey, 'coffee');
    expect(created.toneKey, 'brown');
    expect(find.text('CUSTOM'), findsOneWidget);

    // Back to the main tabs and into the form.
    await tester.tap(find.byTooltip('Back to settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transactions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsOneWidget);
  });

  testWidgets('renames a built-in category and restores it', (tester) async {
    final repo = await _openCategories(tester);

    await tester.tap(find.text('Food & Groceries'));
    await tester.pumpAndSettle();
    expect(find.text('Rename category'), findsOneWidget);
    expect(find.text('Delete category'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('category-name-field')),
      'Groceries',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.current.renamed, {'food': 'Groceries'});
    expect(find.text('Groceries'), findsOneWidget);

    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore “Food & Groceries”'));
    await tester.pumpAndSettle();
    expect(repo.current.renamed, isEmpty);
    expect(find.text('Food & Groceries'), findsOneWidget);
  });

  testWidgets('deletes a custom category after confirmation', (tester) async {
    final repo = await _openCategories(
      tester,
      initial: const UserCategories(custom: [_coffee]),
    );

    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete category'));
    await tester.tap(find.text('Delete category'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Its budgets are deleted too.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repo.deletedIds, [_coffee.id]);
    expect(find.text('Coffee'), findsNothing);
  });

  testWidgets('transactions of a deleted category show under Other', (
    tester,
  ) async {
    final transactions = FakeTransactionRepository([
      Transaction(
        id: 't1',
        type: TransactionType.expense,
        amountMinor: 1500,
        currency: 'PLN',
        categoryId: 'custom_gone00001',
        note: 'Flat white',
        occurredAt: DateTime.now(),
      ),
    ]);
    await pumpPennywise(tester, transactions: transactions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transactions').last);
    await tester.pumpAndSettle();

    expect(find.text('Flat white'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
  });
}
