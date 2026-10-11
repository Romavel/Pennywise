import '../../../core/data/write_result.dart';
import '../../../core/utils/month.dart';
import 'budget.dart';

/// Budgets of the signed-in user. Implementations throw [AppFailure]
/// subclasses on error.
abstract interface class BudgetRepository {
  Stream<List<Budget>> watchMonth(Month month);

  /// Every budget of the user (a small collection: one per category and
  /// month). Used for budget history.
  Stream<List<Budget>> watchAll();

  Stream<Budget?> watchById(String id);

  /// Creates a budget. The category must not have one in [month] yet.
  Future<WriteResult> create({
    required String categoryId,
    required Month month,
    required int limitMinor,
  });

  Future<WriteResult> updateLimit(String id, int limitMinor);

  Future<WriteResult> delete(String id);

  /// Copies [budgets] into [to] in one atomic batch, skipping categories
  /// that already have a budget there.
  Future<WriteResult> copyTo(Month to, List<Budget> budgets);
}
