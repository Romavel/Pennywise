import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/write_result.dart';
import '../../transactions/domain/transaction.dart';
import '../data/category_providers.dart';
import '../domain/category_catalog.dart';
import '../domain/category_repository.dart';

/// Creating, renaming and deleting categories.
final categoryActionsProvider =
    NotifierProvider.autoDispose<CategoryActions, AsyncValue<WriteResult?>>(
      CategoryActions.new,
    );

class CategoryActions extends Notifier<AsyncValue<WriteResult?>> {
  @override
  AsyncValue<WriteResult?> build() => const AsyncData(null);

  Future<void> createCustom({
    required String name,
    required TransactionType type,
    required String iconKey,
    required String toneKey,
  }) => _run(
    (repo) => repo.createCustom(
      name: name,
      type: type,
      iconKey: iconKey,
      toneKey: toneKey,
    ),
  );

  Future<void> updateCustom(CustomCategory category) =>
      _run((repo) => repo.updateCustom(category));

  Future<void> deleteCustom(String id) => _run((repo) => repo.deleteCustom(id));

  Future<void> rename(String builtInId, String name) =>
      _run((repo) => repo.rename(builtInId, name));

  Future<void> resetName(String builtInId) =>
      _run((repo) => repo.resetName(builtInId));

  Future<void> _run(
    Future<WriteResult> Function(CategoryRepository repo) action,
  ) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => action(ref.read(categoryRepositoryProvider)),
    );
    if (ref.mounted) state = result;
  }
}
