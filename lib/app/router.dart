import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_shell.dart';
import '../features/auth/data/auth_providers.dart';
import '../features/auth/domain/app_user.dart';
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
  final session = _SessionState();
  ref.listen(
    firebaseInitProvider,
    (_, next) => session.firebaseInit = next,
    fireImmediately: true,
  );
  ref.listen(
    authStateProvider,
    (_, next) => session.auth = next,
    fireImmediately: true,
  );

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    refreshListenable: session,
    redirect: (context, state) => appRedirect(
      firebaseInit: session.firebaseInit,
      auth: session.auth,
      uri: state.uri,
    ),
    routes: _routes,
  );

  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
});

/// Bridges Riverpod state into go_router's `refreshListenable`.
class _SessionState extends ChangeNotifier {
  AsyncValue<void> _firebaseInit = const AsyncLoading();
  AsyncValue<AppUser?> _auth = const AsyncLoading();

  AsyncValue<void> get firebaseInit => _firebaseInit;
  set firebaseInit(AsyncValue<void> value) {
    _firebaseInit = value;
    notifyListeners();
  }

  AsyncValue<AppUser?> get auth => _auth;
  set auth(AsyncValue<AppUser?> value) {
    _auth = value;
    notifyListeners();
  }
}

/// Route guard:
///
/// 1. Until Firebase is ready and the auth state is known, stay on splash
///    (remembering the requested page).
/// 2. Signed out → `/auth`. Signed in → never `/auth` or splash.
/// 3. After a cold start or login, continue to the remembered page.
String? appRedirect({
  required AsyncValue<void> firebaseInit,
  required AsyncValue<AppUser?> auth,
  required Uri uri,
}) {
  final onSplash = uri.path == AppRoutes.splash;
  final onAuth = uri.path == AppRoutes.auth;

  final firebaseReady = firebaseInit.hasValue && !firebaseInit.hasError;
  final authKnown = auth.hasValue || auth.hasError;
  if (!firebaseReady || !authKnown) {
    if (onSplash) return null;
    return _withFrom(AppRoutes.splash, uri.toString());
  }

  // An auth stream error is treated as signed out.
  final signedIn = auth.value != null;
  final from = (onSplash || onAuth) ? _safeFrom(uri) : null;

  if (!signedIn) {
    if (onAuth) return null;
    // Remember the page only for a cold start; after signing out, a fresh
    // login should start on the dashboard.
    return onSplash && from != null
        ? _withFrom(AppRoutes.auth, from)
        : AppRoutes.auth;
  }

  if (onSplash || onAuth) return from ?? AppRoutes.dashboard;
  return null;
}

String _withFrom(String path, String from) =>
    Uri(path: path, queryParameters: {AppRoutes.fromParam: from}).toString();

/// Returns the remembered page if it is an in-app path (never a full URL)
/// and not one of the entry screens.
String? _safeFrom(Uri uri) {
  final from = uri.queryParameters[AppRoutes.fromParam];
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  final path = Uri.parse(from).path;
  if (path == AppRoutes.splash || path == AppRoutes.auth) return null;
  return from;
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
