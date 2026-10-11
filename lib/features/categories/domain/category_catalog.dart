import 'package:flutter/foundation.dart' hide Category;

import '../../transactions/domain/transaction.dart';
import 'category.dart';
import 'category_styles.dart';
import 'default_categories.dart';

/// What the user has stored about categories: new names for built-in ones
/// and their own categories.
@immutable
class UserCategories {
  const UserCategories({this.renamed = const {}, this.custom = const []});

  /// Built-in category id → the user's name for it.
  final Map<String, String> renamed;
  final List<CustomCategory> custom;
}

/// A category created by the user.
@immutable
class CustomCategory {
  const CustomCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.toneKey,
  });

  /// Custom ids look like `custom_ab12cd34…`, so they can never clash with
  /// built-in ids or the reserved overall-budget id.
  static final idPattern = RegExp(r'^custom_[a-z0-9]{8,32}$');
  static const maxNameLength = 30;

  final String id;
  final String name;
  final TransactionType type;
  final String iconKey;
  final String toneKey;

  Category toCategory() => Category(
    id: id,
    name: name,
    shortName: name,
    type: type,
    icon: CategoryStyles.icon(iconKey),
    tone: CategoryStyles.tone(toneKey),
    isCustom: true,
    iconKey: iconKey,
    toneKey: toneKey,
  );
}

/// All categories available to the user: built-in ones (with the user's
/// names) followed by custom ones.
@immutable
class CategoryCatalog {
  CategoryCatalog([UserCategories user = const UserCategories()])
    : _byId = {
        for (final c in DefaultCategories.all)
          c.id: user.renamed[c.id] == null
              ? c
              : c.copyWith(
                  name: user.renamed[c.id],
                  shortName: user.renamed[c.id],
                ),
        for (final c in user.custom) c.id: c.toCategory(),
      },
      renamedIds = user.renamed.keys.toSet();

  final Map<String, Category> _byId;

  /// Built-in categories the user has renamed.
  final Set<String> renamedIds;

  List<Category> get all => _byId.values.toList();

  List<Category> forType(TransactionType type) =>
      _byId.values.where((c) => c.type == type).toList();

  bool contains(String id) => _byId.containsKey(id);

  /// Unknown ids (e.g. a deleted custom category) resolve to "Other" of the
  /// matching type.
  Category byId(String id, {TransactionType? type}) =>
      _byId[id] ??
      _byId[type == TransactionType.income
          ? DefaultCategories.otherIncome.id
          : DefaultCategories.other.id]!;

  int get customCount => _byId.values.where((c) => c.isCustom).length;
}
