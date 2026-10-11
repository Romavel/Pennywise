import 'dart:async';

import 'package:pennywise/core/utils/month.dart';
import 'package:pennywise/features/transactions/domain/transaction.dart';
import 'package:pennywise/features/transactions/domain/transaction_repository.dart';

/// In-memory [TransactionRepository].
class FakeTransactionRepository implements TransactionRepository {
  FakeTransactionRepository([Iterable<Transaction> initial = const []]) {
    for (final t in initial) {
      _items[t.id] = t;
    }
  }

  final _items = <String, Transaction>{};
  final _changes = StreamController<void>.broadcast();
  var _nextId = 1;

  /// Makes the next write fail with this error.
  Object? nextWriteError;

  /// Makes watch streams fail with this error.
  Object? watchError;

  /// What writes report back.
  WriteResult writeResult = WriteResult.saved;

  final calls = <String>[];

  List<Transaction> get items => _items.values.toList();

  @override
  Stream<List<Transaction>> watchMonth(Month month) => _watch(() {
    final list =
        _items.values.where((t) => month.contains(t.occurredAt)).toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return list;
  });

  @override
  Stream<List<Transaction>> watchAll() => _watch(
    () =>
        _items.values.toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)),
  );

  @override
  Stream<Transaction?> watchById(String id) => _watch(() => _items[id]);

  @override
  Future<WriteResult> create(TransactionDraft draft) => _write('create', () {
    final id = 'new-${_nextId++}';
    _items[id] = _fromDraft(id, draft);
  });

  @override
  Future<WriteResult> update(String id, TransactionDraft draft) =>
      _write('update', () => _items[id] = _fromDraft(id, draft));

  @override
  Future<WriteResult> delete(String id) =>
      _write('delete', () => _items.remove(id));

  Stream<T> _watch<T>(T Function() read) async* {
    if (watchError != null) throw watchError!;
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
    return writeResult;
  }

  static Transaction _fromDraft(String id, TransactionDraft draft) =>
      Transaction(
        id: id,
        type: draft.type,
        amountMinor: draft.amountMinor,
        currency: 'PLN',
        categoryId: draft.categoryId,
        note: draft.note,
        occurredAt: draft.occurredAt,
      );
}
