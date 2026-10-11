import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/app/router.dart';
import 'package:pennywise/app/routes.dart';

void main() {
  const ready = AsyncData<void>(null);
  const loading = AsyncLoading<void>();
  final failed = AsyncError<void>(Exception('boom'), StackTrace.empty);

  String? redirect(AsyncValue<void> init, String location) =>
      appRedirect(firebaseInit: init, uri: Uri.parse(location));

  group('appRedirect', () {
    test('sends any page to splash while Firebase is loading', () {
      expect(
        redirect(loading, '/budgets/abc'),
        '/splash?from=%2Fbudgets%2Fabc',
      );
    });

    test('keeps the user on splash while loading or after an error', () {
      expect(redirect(loading, AppRoutes.splash), isNull);
      expect(redirect(failed, '/splash?from=/reports'), isNull);
    });

    test('sends to splash after an error', () {
      expect(redirect(failed, AppRoutes.dashboard), startsWith('/splash'));
    });

    test('returns to the requested page once ready', () {
      expect(redirect(ready, '/splash?from=%2Fbudgets%2Fabc'), '/budgets/abc');
    });

    test('falls back to the dashboard without a safe "from"', () {
      expect(redirect(ready, AppRoutes.splash), AppRoutes.dashboard);
      expect(
        redirect(ready, '/splash?from=https://evil.example'),
        AppRoutes.dashboard,
      );
      expect(
        redirect(ready, '/splash?from=//evil.example'),
        AppRoutes.dashboard,
      );
      expect(redirect(ready, '/splash?from=/splash'), AppRoutes.dashboard);
    });

    test('leaves regular pages alone once ready', () {
      expect(redirect(ready, AppRoutes.transactions), isNull);
    });
  });
}
