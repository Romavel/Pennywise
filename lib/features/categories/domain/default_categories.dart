import 'package:flutter/material.dart';

import '../../../app/theme/category_palette.dart';
import '../../transactions/domain/transaction.dart';
import 'category.dart';

/// Built-in categories. Their ids are stored in Firestore documents, so they
/// must never change; names and icons can.
abstract final class DefaultCategories {
  static const food = Category(
    id: 'food',
    name: 'Food & Groceries',
    shortName: 'Food',
    type: TransactionType.expense,
    icon: Icons.shopping_cart_outlined,
    tone: CategoryPalette.food,
  );
  static const transport = Category(
    id: 'transport',
    name: 'Transport',
    shortName: 'Transport',
    type: TransactionType.expense,
    icon: Icons.directions_bus_outlined,
    tone: CategoryPalette.transport,
  );
  static const housing = Category(
    id: 'housing',
    name: 'Housing',
    shortName: 'Housing',
    type: TransactionType.expense,
    icon: Icons.home_outlined,
    tone: CategoryPalette.housing,
  );
  static const shopping = Category(
    id: 'shopping',
    name: 'Shopping',
    shortName: 'Shopping',
    type: TransactionType.expense,
    icon: Icons.shopping_bag_outlined,
    tone: CategoryPalette.shopping,
  );
  static const entertainment = Category(
    id: 'entertainment',
    name: 'Entertainment',
    shortName: 'Fun',
    type: TransactionType.expense,
    icon: Icons.play_circle_outline,
    tone: CategoryPalette.entertainment,
  );
  static const health = Category(
    id: 'health',
    name: 'Health',
    shortName: 'Health',
    type: TransactionType.expense,
    icon: Icons.favorite_border,
    tone: CategoryPalette.health,
  );
  static const education = Category(
    id: 'education',
    name: 'Education',
    shortName: 'Education',
    type: TransactionType.expense,
    icon: Icons.menu_book_outlined,
    tone: CategoryPalette.education,
  );
  static const other = Category(
    id: 'other',
    name: 'Other',
    shortName: 'Other',
    type: TransactionType.expense,
    icon: Icons.more_horiz,
    tone: CategoryPalette.other,
  );

  static const salary = Category(
    id: 'salary',
    name: 'Salary',
    shortName: 'Salary',
    type: TransactionType.income,
    icon: Icons.work_outline,
    tone: CategoryPalette.income,
  );
  static const freelance = Category(
    id: 'freelance',
    name: 'Freelance',
    shortName: 'Freelance',
    type: TransactionType.income,
    icon: Icons.laptop_outlined,
    tone: CategoryPalette.income,
  );
  static const investments = Category(
    id: 'investments',
    name: 'Investments',
    shortName: 'Investing',
    type: TransactionType.income,
    icon: Icons.trending_up,
    tone: CategoryPalette.transport,
  );
  static const otherIncome = Category(
    id: 'other_income',
    name: 'Other Income',
    shortName: 'Other',
    type: TransactionType.income,
    icon: Icons.attach_money,
    tone: CategoryPalette.other,
  );

  static const expense = [
    food,
    transport,
    housing,
    shopping,
    entertainment,
    health,
    education,
    other,
  ];
  static const income = [salary, freelance, investments, otherIncome];
  static const all = [...expense, ...income];

  static List<Category> forType(TransactionType type) =>
      type == TransactionType.income ? income : expense;

  static final _byId = {for (final c in all) c.id: c};

  /// Looks up a category; unknown ids (e.g. a deleted custom category)
  /// resolve to "Other" of the matching type.
  static Category byId(String id, {TransactionType? type}) =>
      _byId[id] ?? (type == TransactionType.income ? otherIncome : other);

  static bool exists(String id) => _byId.containsKey(id);
}
