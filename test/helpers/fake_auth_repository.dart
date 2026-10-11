import 'dart:async';

import 'package:pennywise/features/auth/domain/app_user.dart';
import 'package:pennywise/features/auth/domain/auth_repository.dart';

const testUser = AppUser(
  uid: 'u1',
  email: 'jan@example.com',
  displayName: 'Jan',
);

/// In-memory [AuthRepository]. Set [nextError] to make the next call fail,
/// or [pending] to keep calls in flight until it completes.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.currentUser});

  AppUser? currentUser;
  final _changes = StreamController<AppUser?>.broadcast();

  Object? nextError;
  Completer<void>? pending;
  final calls = <String>[];

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield currentUser;
    yield* _changes.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) =>
      _call('signIn', () => _emit(AppUser(uid: 'u-$email', email: email)));

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) => _call(
    'signUp',
    () =>
        _emit(AppUser(uid: 'u-$email', email: email, displayName: displayName)),
  );

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _call('sendPasswordResetEmail', () {});

  @override
  Future<void> signOut() => _call('signOut', () => _emit(null));

  void _emit(AppUser? user) {
    currentUser = user;
    _changes.add(user);
  }

  Future<void> _call(String name, void Function() onSuccess) async {
    calls.add(name);
    if (pending != null) await pending!.future;
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    onSuccess();
  }
}
