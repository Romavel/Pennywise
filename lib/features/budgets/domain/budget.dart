import 'package:flutter/foundation.dart';

import '../../../core/utils/month.dart';

/// A monthly spending limit for one expense category.
@immutable
class Budget {
  const Budget({
    required this.categoryId,
    required this.month,
    required this.limitMinor,
    required this.currency,
    this.createdAt,
    this.updatedAt,
  });

  final String categoryId;
  final Month month;
  final int limitMinor;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// One budget per category and month, so the id is derived from both.
  /// This also makes "create" idempotent and duplicates impossible.
  String get id => idFor(month, categoryId);

  static String idFor(Month month, String categoryId) =>
      '${month.key}_$categoryId';

  /// Splits an id produced by [idFor]; `null` if it doesn't have that shape.
  static ({Month month, String categoryId})? parseId(String id) {
    final separator = id.indexOf('_');
    if (separator != 7) return null;
    try {
      return (
        month: Month.parse(id.substring(0, separator)),
        categoryId: id.substring(separator + 1),
      );
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Budget &&
      other.categoryId == categoryId &&
      other.month == month &&
      other.limitMinor == limitMinor &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(categoryId, month, limitMinor, currency);

  @override
  String toString() => 'Budget($id)';
}
