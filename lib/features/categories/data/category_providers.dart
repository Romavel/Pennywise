import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../domain/category_catalog.dart';
import '../domain/category_repository.dart';
import 'firestore_category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final uid = ref.watch(authStateProvider.select((auth) => auth.value?.uid));
  if (uid == null) {
    throw StateError('Categories are only available when signed in.');
  }
  return FirestoreCategoryRepository(FirebaseFirestore.instance, uid: uid);
});

final userCategoriesProvider = StreamProvider<UserCategories>(
  (ref) => ref.watch(categoryRepositoryProvider).watch(),
);

/// Categories available to the user. Falls back to the built-in ones while
/// the user's categories load (or if they fail to load), so screens never
/// wait on it.
final categoryCatalogProvider = Provider<CategoryCatalog>((ref) {
  final user = ref.watch(userCategoriesProvider).value;
  return CategoryCatalog(user ?? const UserCategories());
});
