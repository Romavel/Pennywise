// Renders README screenshots from the real widgets with sample data:
//
//   flutter test screenshots --update-goldens
//
// The PNGs are written to docs/screenshots/. Not part of the regular test
// run (`flutter test` only looks in test/).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pennywise/core/utils/month.dart';
import 'package:pennywise/features/budgets/domain/budget.dart';
import 'package:pennywise/features/settings/domain/user_profile.dart';
import 'package:pennywise/features/transactions/domain/transaction.dart';

import '../test/helpers/fake_auth_repository.dart';
import '../test/helpers/fake_budget_repository.dart';
import '../test/helpers/fake_settings_repositories.dart';
import '../test/helpers/fake_transaction_repository.dart';
import '../test/helpers/pump_app.dart';

Future<void> _loadIconFont() async {
  // The test environment has no icon font; load the one from the SDK.
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(
        Platform.resolvedExecutable,
      ).parent.parent.parent.parent.parent.parent.path;
  final font = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
  await loader.load();
}

List<Transaction> _transactions() {
  final now = DateTime.now();
  final month = Month.current();
  var id = 0;
  Transaction tx(
    String category,
    int amount,
    String note,
    DateTime at, {
    bool income = false,
  }) => Transaction(
    id: 't${id++}',
    type: income ? TransactionType.income : TransactionType.expense,
    amountMinor: amount,
    currency: 'PLN',
    categoryId: category,
    note: note,
    occurredAt: at,
  );
  DateTime day(Month m, int d) =>
      DateTime(m.year, m.month, d.clamp(1, now.day), 12);

  final list = <Transaction>[
    tx('food', 8640, 'Weekly groceries', now),
    tx(
      'transport',
      3200,
      'Ride to the office',
      now.subtract(const Duration(minutes: 30)),
    ),
    tx(
      'freelance',
      100000,
      'Landing page project',
      day(month, 9),
      income: true,
    ),
    tx('entertainment', 4800, 'Cinema tickets', day(month, 9)),
    tx('health', 3990, 'Pharmacy', day(month, 7)),
    tx('shopping', 18990, 'Autumn jacket', day(month, 7)),
    tx('housing', 165000, 'Rent', day(month, 2)),
    tx('salary', 720000, 'October salary', day(month, 1), income: true),
    tx('food', 75620, 'Groceries', day(month, 4)),
    tx('transport', 27800, 'Monthly transit pass', day(month, 1)),
  ];
  var m = month.previous;
  for (var i = 0; i < 5; i++) {
    final d = DateTime(m.year, m.month, 10, 12);
    list
      ..add(tx('salary', 720000, 'Salary', d, income: true))
      ..add(tx('housing', 165000, 'Rent', d))
      ..add(tx('food', 72000 + i * 8000, 'Groceries', d))
      ..add(tx('transport', [32000, 26000, 34500, 29000, 24000][i], 'Fuel', d))
      ..add(tx('shopping', 28990 - i * 3000, 'Shopping', d));
    m = m.previous;
  }
  return list;
}

List<Budget> _budgets() {
  final budgets = <Budget>[];
  var m = Month.current();
  for (var i = 0; i < 6; i++) {
    budgets
      ..add(
        Budget(
          categoryId: 'housing',
          month: m,
          limitMinor: 170000,
          currency: 'PLN',
        ),
      )
      ..add(
        Budget(
          categoryId: 'food',
          month: m,
          limitMinor: 120000,
          currency: 'PLN',
        ),
      )
      ..add(
        Budget(
          categoryId: 'transport',
          month: m,
          limitMinor: 30000,
          currency: 'PLN',
        ),
      )
      ..add(
        Budget(
          categoryId: 'shopping',
          month: m,
          limitMinor: 40000,
          currency: 'PLN',
        ),
      );
    m = m.previous;
  }
  return budgets;
}

Future<void> _pump(
  WidgetTester tester, {
  ThemeMode theme = ThemeMode.light,
}) async {
  // Real shadows instead of the test outline; restored in [_shoot].
  debugDisableShadows = false;
  await pumpPennywise(
    tester,
    auth: FakeAuthRepository(currentUser: testUser),
    profile: FakeProfileRepository(
      UserProfile(displayName: 'Jakub', themeMode: theme),
    ),
    transactions: FakeTransactionRepository(_transactions()),
    budgets: FakeBudgetRepository(_budgets()),
  );
  await tester.pumpAndSettle();
}

/// Captures the screen. Flutter checks that the shadow flag set in [_pump]
/// is restored before the test ends.
Future<void> _shoot(WidgetTester tester, String name) async {
  // Fonts load asynchronously; wait so no text renders as placeholder boxes.
  await tester.runAsync(GoogleFonts.pendingFonts);
  await tester.pumpAndSettle();
  try {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/$name.png'),
    );
  } finally {
    debugDisableShadows = true;
  }
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadIconFont);

  testWidgets('dashboard', (tester) async {
    await _pump(tester);
    await _shoot(tester, 'dashboard');
  });

  testWidgets('dashboard dark', (tester) async {
    await _pump(tester, theme: ThemeMode.dark);
    await _shoot(tester, 'dashboard_dark');
  });

  testWidgets('transactions', (tester) async {
    await _pump(tester);
    await _openTab(tester, 'Transactions');
    await _shoot(tester, 'transactions');
  });

  testWidgets('transaction form', (tester) async {
    await _pump(tester);
    await _openTab(tester, 'Transactions');
    await tester.tap(find.text('Weekly groceries'));
    await tester.pumpAndSettle();
    await _shoot(tester, 'transaction_form');
  });

  testWidgets('budgets', (tester) async {
    await _pump(tester);
    await _openTab(tester, 'Budgets');
    await _shoot(tester, 'budgets');
  });

  testWidgets('budget detail', (tester) async {
    await _pump(tester);
    await _openTab(tester, 'Budgets');
    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();
    await _shoot(tester, 'budget_detail');
  });

  testWidgets('reports', (tester) async {
    await _pump(tester);
    await _openTab(tester, 'Reports');
    await _shoot(tester, 'reports');
  });

  testWidgets('settings', (tester) async {
    await _pump(tester);
    await _openTab(tester, 'Settings');
    await _shoot(tester, 'settings');
  });
}
