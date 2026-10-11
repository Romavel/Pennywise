import 'package:flutter/foundation.dart';

enum TransactionType {
  income,
  expense;

  static TransactionType parse(String value) =>
      values.firstWhere((t) => t.name == value);
}

/// A saved income or expense.
@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.categoryId,
    required this.occurredAt,
    this.note = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final TransactionType type;

  /// Always positive; [type] says whether money came in or went out.
  final int amountMinor;
  final String currency;
  final String categoryId;
  final String note;
  final DateTime occurredAt;

  /// Set by the server; `null` until the first write is acknowledged.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isIncome => type == TransactionType.income;

  /// Amount with sign: positive for income, negative for expenses.
  int get signedAmountMinor => isIncome ? amountMinor : -amountMinor;

  TransactionDraft toDraft() => TransactionDraft(
    type: type,
    amountMinor: amountMinor,
    categoryId: categoryId,
    occurredAt: occurredAt,
    note: note,
  );

  @override
  bool operator ==(Object other) =>
      other is Transaction &&
      other.id == id &&
      other.type == type &&
      other.amountMinor == amountMinor &&
      other.currency == currency &&
      other.categoryId == categoryId &&
      other.note == note &&
      other.occurredAt == occurredAt &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amountMinor,
    currency,
    categoryId,
    note,
    occurredAt,
    createdAt,
    updatedAt,
  );

  // Amount and note are left out so financial data is not logged by accident.
  @override
  String toString() => 'Transaction($id, ${type.name})';
}

/// The user-editable part of a transaction, as submitted by the form.
@immutable
class TransactionDraft {
  const TransactionDraft({
    required this.type,
    required this.amountMinor,
    required this.categoryId,
    required this.occurredAt,
    this.note = '',
  });

  final TransactionType type;
  final int amountMinor;
  final String categoryId;
  final DateTime occurredAt;
  final String note;

  @override
  bool operator ==(Object other) =>
      other is TransactionDraft &&
      other.type == type &&
      other.amountMinor == amountMinor &&
      other.categoryId == categoryId &&
      other.occurredAt == occurredAt &&
      other.note == note;

  @override
  int get hashCode =>
      Object.hash(type, amountMinor, categoryId, occurredAt, note);
}
