import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennywise/app/theme/app_colors.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('opens on the dashboard once Firebase is ready', (tester) async {
    await pumpPennywise(tester);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.text('Balance, monthly totals and budgets arrive in stage 4.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Add transaction'), findsOneWidget);
  });

  testWidgets('bottom navigation switches tabs and toggles the add button', (
    tester,
  ) async {
    await pumpPennywise(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Budgets'));
    await tester.pumpAndSettle();
    expect(
      find.text('Monthly category budgets arrive in stage 5.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Add transaction'), findsNothing);

    await tester.tap(find.text('Transactions').last);
    await tester.pumpAndSettle();
    expect(
      find.text('The transaction list and filters arrive in stage 3.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Add transaction'), findsOneWidget);
  });

  testWidgets('add button opens the form above the bottom navigation', (
    tester,
  ) async {
    await pumpPennywise(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();
    expect(find.text('New transaction'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('settings opens categories and switches to the dark theme', (
    tester,
  ) async {
    await pumpPennywise(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(context.pwColors, PennywiseColors.dark);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(
      find.text('Built-in and custom categories arrive in stage 6.'),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
  });
}
