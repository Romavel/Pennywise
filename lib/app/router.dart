import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_shell.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/budgets/presentation/budget_detail_screen.dart';
import '../features/budgets/presentation/budgets_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/transactions/presentation/transaction_form_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import 'providers.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final initState = ValueNotifier<AsyncValue<void>>(const AsyncLoading());
  ref.listen(
    firebaseInitProvider,
    (_, next) => initState.value = next,
    fireImmediately: true,
  );

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    refreshListenable: initState,
    redirect: (context, state) =>
        appRedirect(firebaseInit: initState.value, uri: state.uri),
    routes: _routes,
  );

  ref.onDispose(() {
    router.dispose();
    initState.dispose();
  });
  return router;
});

/// Keeps the user on the splash screen until Firebase is ready, then sends
/// them to the page they originally asked for.
///
/// Authentication guards are added here in stage 2.
String? appRedirect({
  required AsyncValue<void> firebaseInit,
  required Uri uri,
}) {
  final onSplash = uri.path == AppRoutes.splash;
  final ready = firebaseInit.hasValue && !firebaseInit.hasError;

  if (!ready) {
    if (onSplash) return null;
    return Uri(
      path: AppRoutes.splash,
      queryParameters: {AppRoutes.fromParam: uri.toString()},
    ).toString();
  }

  if (onSplash) {
    final from = uri.queryParameters[AppRoutes.fromParam];
    // Only accept in-app paths, never a full URL.
    final isSafe =
        from != null &&
        from.startsWith('/') &&
        !from.startsWith('//') &&
        !from.startsWith(AppRoutes.splash);
    return isSafe ? from : AppRoutes.dashboard;
  }
  return null;
}

final _routes = <RouteBase>[
  GoRoute(
    path: AppRoutes.splash,
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: AppRoutes.auth,
    builder: (context, state) => const AuthScreen(),
  ),
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        AppShell(navigationShell: navigationShell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.transactions,
            builder: (context, state) => const TransactionsScreen(),
            routes: [
              // Full-screen routes, shown above the bottom navigation.
              GoRoute(
                path: 'new',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => const MaterialPage(
                  fullscreenDialog: true,
                  child: TransactionFormScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => TransactionFormScreen(
                  transactionId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.budgets,
            builder: (context, state) => const BudgetsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    BudgetDetailScreen(budgetId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'categories',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const CategoriesScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
