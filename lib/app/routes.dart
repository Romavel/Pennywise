/// Route paths. Matches the screen map in `docs/design/DESIGN_TOKENS.md`.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const auth = '/auth';

  static const dashboard = '/dashboard';
  static const transactions = '/transactions';
  static const budgets = '/budgets';
  static const reports = '/reports';
  static const settings = '/settings';

  static const transactionNew = '/transactions/new';
  static String transactionEdit(String id) => '/transactions/$id';
  static String budgetDetail(String id) => '/budgets/$id';
  static const categories = '/settings/categories';

  /// Query parameter the splash redirect uses to remember the requested page.
  static const fromParam = 'from';
}
