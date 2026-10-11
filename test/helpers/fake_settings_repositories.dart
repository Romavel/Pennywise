import 'dart:async';

import 'package:pennywise/core/data/write_result.dart';
import 'package:pennywise/features/auth/domain/auth_failure.dart';
import 'package:pennywise/features/categories/domain/category_catalog.dart';
import 'package:pennywise/features/categories/domain/category_repository.dart';
import 'package:pennywise/features/settings/domain/account_repository.dart';
import 'package:pennywise/features/settings/domain/profile_repository.dart';
import 'package:pennywise/features/settings/domain/user_profile.dart';
import 'package:pennywise/features/transactions/domain/transaction.dart';

import 'fake_auth_repository.dart';

/// In-memory [ProfileRepository]; `null` until something is saved.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository([this.profile]);

  UserProfile? profile;
  final _changes = StreamController<void>.broadcast();
  final saved = <UserProfile>[];

  @override
  Stream<UserProfile?> watch() async* {
    yield profile;
    await for (final _ in _changes.stream) {
      yield profile;
    }
  }

  @override
  Future<WriteResult> save(UserProfile profile) async {
    saved.add(profile);
    this.profile = profile;
    _changes.add(null);
    return WriteResult.saved;
  }
}

/// In-memory [CategoryRepository].
class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository([UserCategories initial = const UserCategories()])
    : _renamed = {...initial.renamed},
      _custom = [...initial.custom];

  final Map<String, String> _renamed;
  final List<CustomCategory> _custom;
  final _changes = StreamController<void>.broadcast();
  var _nextId = 1;
  final calls = <String>[];

  /// Ids of custom categories deleted, whose budgets the real repository
  /// deletes as well.
  final deletedIds = <String>[];

  UserCategories get current =>
      UserCategories(renamed: {..._renamed}, custom: [..._custom]);

  @override
  Stream<UserCategories> watch() async* {
    yield current;
    await for (final _ in _changes.stream) {
      yield current;
    }
  }

  @override
  Future<WriteResult> rename(String builtInId, String name) =>
      _write('rename', () => _renamed[builtInId] = name);

  @override
  Future<WriteResult> resetName(String builtInId) =>
      _write('resetName', () => _renamed.remove(builtInId));

  @override
  Future<WriteResult> createCustom({
    required String name,
    required TransactionType type,
    required String iconKey,
    required String toneKey,
  }) => _write(
    'createCustom',
    () => _custom.add(
      CustomCategory(
        id: 'custom_test${(_nextId++).toString().padLeft(5, '0')}',
        name: name,
        type: type,
        iconKey: iconKey,
        toneKey: toneKey,
      ),
    ),
  );

  @override
  Future<WriteResult> updateCustom(CustomCategory category) =>
      _write('updateCustom', () {
        final i = _custom.indexWhere((c) => c.id == category.id);
        _custom[i] = category;
      });

  @override
  Future<WriteResult> deleteCustom(String id) => _write('deleteCustom', () {
    _custom.removeWhere((c) => c.id == id);
    deletedIds.add(id);
  });

  Future<WriteResult> _write(String name, void Function() apply) async {
    calls.add(name);
    apply();
    _changes.add(null);
    return WriteResult.saved;
  }
}

/// [AccountRepository] that accepts [password] and signs the user out of
/// [auth] when the account is deleted.
class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository(this.auth, {this.password = 'password123'});

  final FakeAuthRepository auth;
  final String password;
  final calls = <String>[];
  String? displayName;

  /// Makes the server step fail.
  bool failDeletion = false;

  @override
  Future<void> updateDisplayName(String name) async {
    calls.add('updateDisplayName');
    displayName = name;
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    calls.add('deleteAccount');
    if (password != this.password) {
      throw const AuthFailure(AuthFailureCode.invalidCredentials);
    }
    if (failDeletion) throw const AccountDeletionFailure();
    await auth.signOut();
  }
}
