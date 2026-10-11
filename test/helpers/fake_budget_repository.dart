import 'dart:async';

import 'package:pennywise/core/data/write_result.dart';
import 'package:pennywise/core/utils/month.dart';
import 'package:pennywise/features/budgets/domain/budget.dart';
import 'package:pennywise/features/budgets/domain/budget_repository.dart';

/// In-memory [BudgetRepository].
class FakeBudgetRepository implements BudgetRepository {
  FakeBudgetRepository([Iterable<Budget> initial = const []]) {
    for (final b in initial) {
      _items[b.id] = b;
    }
  }

  final _items = <String, Budget>{};
  final _changes = StreamController<void>.broadcast();

  Object? nextWriteError;
  final calls = <String>[];

  List<Budget> get items => _items.values.toList();

  @override
  Stream<List<Budget>> watchMonth(Month month) =>
      _watch(() => _items.values.where((b) => b.month == month).toList());

  @override
  Stream<List<Budget>> watchAll() => _watch(() => _items.values.toList());

  @override
  Stream<Budget?> watchById(String id) => _watch(() => _items[id]);

  @override
  Future<WriteResult> create({
    required String categoryId,
    required Month month,
    required int limitMinor,
  }) => _write('create', () {
    final budget = Budget(
      categoryId: categoryId,
      month: month,
      limitMinor: limitMinor,
      currency: 'PLN',
    );
    _items[budget.id] = budget;
  });

  @override
  Future<WriteResult> updateLimit(String id, int limitMinor) =>
      _write('updateLimit', () {
        final b = _items[id]!;
        _items[id] = Budget(
          categoryId: b.categoryId,
          month: b.month,
          limitMinor: limitMinor,
          currency: b.currency,
        );
      });

  @override
  Future<WriteResult> delete(String id) =>
      _write('delete', () => _items.remove(id));

  @override
  Future<WriteResult> copyTo(Month to, List<Budget> budgets) =>
      _write('copyTo', () {
        for (final b in budgets) {
          final copy = Budget(
            categoryId: b.categoryId,
            month: to,
            limitMinor: b.limitMinor,
            currency: b.currency,
          );
          _items[copy.id] = copy;
        }
      });

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  Future<WriteResult> _write(String name, void Function() apply) async {
    calls.add(name);
    final error = nextWriteError;
    if (error != null) {
      nextWriteError = null;
      throw error;
    }
    apply();
    _changes.add(null);
    return WriteResult.saved;
  }
}
