import '../../../core/utils/month.dart';
import 'transaction.dart';

/// Outcome of a write.
enum WriteResult {
  /// Confirmed by the server.
  saved,

  /// Stored on the device; it syncs when the connection comes back.
  pendingSync,
}

/// Transactions of the signed-in user. Implementations throw [AppFailure]
/// subclasses on error.
abstract interface class TransactionRepository {
  /// Transactions whose date falls in [month], newest first. Emits again on
  /// every change, including local writes that are not yet synced.
  Stream<List<Transaction>> watchMonth(Month month);

  /// A single transaction, or `null` once it no longer exists.
  Stream<Transaction?> watchById(String id);

  Future<WriteResult> create(TransactionDraft draft);

  Future<WriteResult> update(String id, TransactionDraft draft);

  Future<WriteResult> delete(String id);
}
