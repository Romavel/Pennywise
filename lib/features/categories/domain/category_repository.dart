import '../../../core/data/write_result.dart';
import '../../transactions/domain/transaction.dart';
import 'category_catalog.dart';

/// The user's category names and custom categories. Implementations throw
/// [AppFailure] subclasses on error.
abstract interface class CategoryRepository {
  Stream<UserCategories> watch();

  /// Gives a built-in category a different name.
  Future<WriteResult> rename(String builtInId, String name);

  /// Restores a built-in category's original name.
  Future<WriteResult> resetName(String builtInId);

  Future<WriteResult> createCustom({
    required String name,
    required TransactionType type,
    required String iconKey,
    required String toneKey,
  });

  Future<WriteResult> updateCustom(CustomCategory category);

  /// Deletes a custom category together with its budgets. Transactions keep
  /// their category id and are shown under "Other".
  Future<WriteResult> deleteCustom(String id);
}
