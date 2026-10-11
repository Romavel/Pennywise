import 'package:flutter/material.dart';

import '../../../app/theme/category_palette.dart';
import '../../transactions/domain/transaction.dart';

/// A transaction category. Built-in categories have stable ids that never
/// change, independent of their display names.
@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.shortName,
    required this.type,
    required this.icon,
    required this.tone,
  });

  final String id;
  final String name;

  /// Fits under a category tile in the form grid.
  final String shortName;
  final TransactionType type;
  final IconData icon;
  final CategoryTone tone;

  @override
  bool operator ==(Object other) => other is Category && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Category($id)';
}
