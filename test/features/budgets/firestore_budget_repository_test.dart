import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/core/utils/month.dart';
import 'package:pennywise/features/budgets/data/firestore_budget_repository.dart';
import 'package:pennywise/features/budgets/domain/budget.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreBudgetRepository repository;
  const october = Month(2026, 10);
  const november = Month(2026, 11);

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreBudgetRepository(
      firestore,
      uid: 'alice',
      currency: 'PLN',
    );
  });

  test('create stores the budget under a month-and-category id', () async {
    await repository.create(
      categoryId: 'food',
      month: october,
      limitMinor: 120000,
    );

    final doc = await firestore.doc('users/alice/budgets/2026-10_food').get();
    expect(doc.data(), containsPair('monthKey', '2026-10'));
    expect(doc.data(), containsPair('limitMinor', 120000));
    expect(doc.data(), containsPair('currency', 'PLN'));
    expect(doc.data()!.keys, containsAll(['createdAt', 'updatedAt']));
  });

  test('watchMonth only returns that month', () async {
    await repository.create(categoryId: 'food', month: october, limitMinor: 1);
    await repository.create(categoryId: 'food', month: november, limitMinor: 2);

    final budgets = await repository.watchMonth(october).first;
    expect(budgets.single.limitMinor, 1);
    expect((await repository.watchAll().first), hasLength(2));
  });

  test('updateLimit and delete', () async {
    await repository.create(categoryId: 'food', month: october, limitMinor: 1);
    const id = '2026-10_food';

    await repository.updateLimit(id, 5000);
    expect((await repository.watchById(id).first)?.limitMinor, 5000);

    await repository.delete(id);
    expect(await repository.watchById(id).first, isNull);
  });

  test('copyTo creates the budgets in the target month in one batch', () async {
    final source = [
      const Budget(
        categoryId: 'food',
        month: october,
        limitMinor: 120000,
        currency: 'PLN',
      ),
      const Budget(
        categoryId: 'housing',
        month: october,
        limitMinor: 170000,
        currency: 'PLN',
      ),
    ];

    await repository.copyTo(november, source);

    final copied = await repository.watchMonth(november).first;
    expect(
      copied.map((b) => b.id),
      unorderedEquals(['2026-11_food', '2026-11_housing']),
    );
    expect(copied.map((b) => b.limitMinor), unorderedEquals([120000, 170000]));
  });
}
