import 'package:flutter/material.dart';

import '../../../app/theme/category_palette.dart';
import '../../categories/domain/category.dart';
import '../../categories/domain/default_categories.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/budget.dart';

/// How the overall budget is shown wherever a category would be.
const overallBudgetCategory = Category(
  id: Budget.overallCategoryId,
  name: 'Overall budget',
  shortName: 'Overall',
  type: TransactionType.expense,
  icon: Icons.account_balance_wallet_outlined,
  tone: CategoryTone(Color(0xFFDCEBE6), Color(0xFF0F4C45)),
);

/// The category a budget is for, or [overallBudgetCategory].
Category categoryForBudget(String categoryId) =>
    categoryId == Budget.overallCategoryId
    ? overallBudgetCategory
    : DefaultCategories.byId(categoryId);
