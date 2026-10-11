import 'dart:math';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/features/categories/data/firestore_category_repository.dart';
import 'package:pennywise/features/categories/domain/category_catalog.dart';
import 'package:pennywise/features/categories/domain/default_categories.dart';
import 'package:pennywise/features/settings/data/firestore_profile_repository.dart';
import 'package:pennywise/features/settings/domain/user_profile.dart';
import 'package:pennywise/features/transactions/domain/transaction.dart';

void main() {
  group('CategoryCatalog', () {
    const coffee = CustomCategory(
      id: 'custom_coffee0001',
      name: 'Coffee',
      type: TransactionType.expense,
      iconKey: 'coffee',
      toneKey: 'brown',
    );
    final catalog = CategoryCatalog(
      const UserCategories(renamed: {'food': 'Groceries'}, custom: [coffee]),
    );

    test('applies new names to built-in categories', () {
      expect(catalog.byId('food').name, 'Groceries');
      expect(catalog.byId('food').isCustom, isFalse);
      expect(catalog.renamedIds, {'food'});
    });

    test('adds custom categories after the built-in ones', () {
      final expense = catalog.forType(TransactionType.expense);
      expect(expense.length, DefaultCategories.expense.length + 1);
      expect(expense.last.name, 'Coffee');
      expect(expense.last.isCustom, isTrue);
      expect(expense.last.icon, Icons.local_cafe_outlined);
      expect(catalog.forType(TransactionType.income).length, 4);
      expect(catalog.customCount, 1);
    });

    test('unknown ids fall back to "Other" of the right type', () {
      expect(catalog.byId('custom_deleted00').id, 'other');
      expect(
        catalog.byId('custom_deleted00', type: TransactionType.income).id,
        'other_income',
      );
    });
  });

  group('FirestoreCategoryRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreCategoryRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreCategoryRepository(
        firestore,
        uid: 'alice',
        random: Random(1),
      );
    });

    test('stores renames under the built-in id', () async {
      await repository.rename('food', ' Groceries ');
      expect(
        (await firestore.doc('users/alice/categories/food').get()).data(),
        containsPair('name', 'Groceries'),
      );
      expect((await repository.watch().first).renamed, {'food': 'Groceries'});

      await repository.resetName('food');
      expect((await repository.watch().first).renamed, isEmpty);
    });

    test('creates custom categories with a custom_ id', () async {
      await repository.createCustom(
        name: 'Coffee',
        type: TransactionType.expense,
        iconKey: 'coffee',
        toneKey: 'brown',
      );

      final custom = (await repository.watch().first).custom.single;
      expect(CustomCategory.idPattern.hasMatch(custom.id), isTrue);
      expect(custom.name, 'Coffee');
      expect(custom.iconKey, 'coffee');
    });

    test('deleting a custom category also deletes its budgets', () async {
      await repository.createCustom(
        name: 'Coffee',
        type: TransactionType.expense,
        iconKey: 'coffee',
        toneKey: 'brown',
      );
      final id = (await repository.watch().first).custom.single.id;
      final budgets = firestore.collection('users/alice/budgets');
      await budgets.doc('2026-10_$id').set({'categoryId': id});
      await budgets.doc('2026-11_$id').set({'categoryId': id});
      await budgets.doc('2026-10_food').set({'categoryId': 'food'});

      await repository.deleteCustom(id);

      expect((await repository.watch().first).custom, isEmpty);
      final left = await budgets.get();
      expect(left.docs.map((d) => d.id), ['2026-10_food']);
    });
  });

  group('FirestoreProfileRepository', () {
    test('is null until saved, then round-trips', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FirestoreProfileRepository(firestore, uid: 'alice');
      expect(await repository.watch().first, isNull);

      const profile = UserProfile(
        displayName: 'Alice',
        currency: 'EUR',
        themeMode: ThemeMode.dark,
      );
      await repository.save(profile);

      expect(await repository.watch().first, profile);
      expect(
        (await firestore.doc('users/alice').get()).data(),
        containsPair('themeMode', 'dark'),
      );
    });
  });
}
