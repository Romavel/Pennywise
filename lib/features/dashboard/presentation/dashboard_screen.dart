import 'package:flutter/material.dart';

import '../../../core/widgets/screen_placeholder.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ScreenPlaceholder(
        title: 'Dashboard',
        description: 'Balance, monthly totals and budgets arrive in stage 4.',
      ),
    );
  }
}
