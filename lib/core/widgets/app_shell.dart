import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';

/// Scaffold for the five main tabs: bottom navigation plus the
/// "add transaction" button on Dashboard and Transactions.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _tabsWithAddButton = {0, 1};

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.space_dashboard_outlined),
      selectedIcon: Icon(Icons.space_dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(icon: Icon(Icons.swap_vert), label: 'Transactions'),
    NavigationDestination(
      icon: Icon(Icons.pie_chart_outline),
      selectedIcon: Icon(Icons.pie_chart),
      label: 'Budgets',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: 'Reports',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      floatingActionButton: _tabsWithAddButton.contains(index)
          ? FloatingActionButton(
              tooltip: 'Add transaction',
              onPressed: () => context.push(AppRoutes.transactionNew),
              child: const Icon(Icons.add, size: 26),
            )
          : null,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          destinations: _destinations,
          // Tapping the active tab returns to its root.
          onDestinationSelected: (i) =>
              navigationShell.goBranch(i, initialLocation: i == index),
        ),
      ),
    );
  }
}
