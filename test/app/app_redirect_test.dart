import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/app/router.dart';
import 'package:pennywise/app/routes.dart';
import 'package:pennywise/features/auth/domain/app_user.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  const ready = AsyncData<void>(null);
  const loading = AsyncLoading<void>();
  final failed = AsyncError<void>(Exception('boom'), StackTrace.empty);

  const signedIn = AsyncData<AppUser?>(testUser);
  const signedOut = AsyncData<AppUser?>(null);
  const authLoading = AsyncLoading<AppUser?>();

  String? redirect(
    String location, {
    AsyncValue<void> init = ready,
    AsyncValue<AppUser?> auth = signedIn,
  }) => appRedirect(firebaseInit: init, auth: auth, uri: Uri.parse(location));

  group('while starting up', () {
    test('sends any page to splash and remembers it', () {
      expect(
        redirect('/budgets/abc', init: loading),
        '/splash?from=%2Fbudgets%2Fabc',
      );
    });

    test('waits on splash until the auth state is known', () {
      expect(redirect('/dashboard', auth: authLoading), startsWith('/splash'));
      expect(redirect(AppRoutes.splash, auth: authLoading), isNull);
    });

    test('stays on splash after a Firebase error', () {
      expect(redirect('/splash?from=/reports', init: failed), isNull);
      expect(
        redirect(AppRoutes.dashboard, init: failed),
        startsWith('/splash'),
      );
    });
  });

  group('signed out', () {
    test('protected pages redirect to auth', () {
      expect(redirect(AppRoutes.dashboard, auth: signedOut), AppRoutes.auth);
      expect(redirect('/transactions/t1', auth: signedOut), AppRoutes.auth);
    });

    test('auth screen is allowed', () {
      expect(redirect(AppRoutes.auth, auth: signedOut), isNull);
    });

    test('a cold-start deep link is kept through the auth screen', () {
      expect(
        redirect('/splash?from=%2Fbudgets%2Fb1', auth: signedOut),
        '/auth?from=%2Fbudgets%2Fb1',
      );
      expect(redirect(AppRoutes.splash, auth: signedOut), AppRoutes.auth);
    });

    test('an auth stream error counts as signed out', () {
      final error = AsyncError<AppUser?>(Exception('x'), StackTrace.empty);
      expect(redirect(AppRoutes.dashboard, auth: error), AppRoutes.auth);
    });
  });

  group('signed in', () {
    test('leaves the auth screen for the remembered page', () {
      expect(redirect('/auth?from=%2Freports'), '/reports');
      expect(redirect(AppRoutes.auth), AppRoutes.dashboard);
    });

    test('leaves splash for the remembered page', () {
      expect(redirect('/splash?from=%2Fbudgets%2Fabc'), '/budgets/abc');
      expect(redirect(AppRoutes.splash), AppRoutes.dashboard);
    });

    test('ignores unsafe or looping "from" values', () {
      for (final from in [
        'https://evil.example',
        '//evil.example',
        '/splash',
        '/auth?from=/x',
      ]) {
        final location = Uri(
          path: AppRoutes.auth,
          queryParameters: {'from': from},
        ).toString();
        expect(redirect(location), AppRoutes.dashboard, reason: from);
      }
    });

    test('leaves regular pages alone', () {
      expect(redirect(AppRoutes.transactions), isNull);
      expect(redirect('/settings/categories'), isNull);
    });
  });
}
